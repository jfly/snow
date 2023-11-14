import pulumi
import pulumi_kubernetes as kubernetes
from typing import Optional
from pulumi_crds import traefik
from .util import snow_deployment
from .util import http_service
from .util import http_ingress
from .deage import deage
from enum import Enum
from enum import auto
import pulumi_keycloak as keycloak


class Access(Enum):
    INTERNET_UNSECURED = auto()
    INTERNET_BEHIND_SSO_RAREMY = auto()
    INTERNET_BEHIND_SSO_FAMILY = auto()
    LAN_ONLY = auto()


class Snowauth:
    def __init__(self):
        self.snow_realm = self._declare_keycloak_realm()

        # Middleware to add HSTS headers. TODO: actually use this everywhere we
        # do http, or figure out a generic way of enforicng this (perhaps
        # something clever with an admission controller?)
        self._strict_https_middleware = traefik.v1alpha1.Middleware(
            "strict-https",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(
                name="strict-https",
                namespace="default",
            ),
            spec=traefik.v1alpha1.MiddlewareSpecArgs(
                headers=traefik.v1alpha1.MiddlewareSpecHeadersArgs(
                    # Settings come from these nextcloud docs:
                    # https://docs.nextcloud.com/server/27/admin_manual/installation/harden_server.html#enable-http-strict-transport-security
                    sts_seconds=15552000,
                    sts_include_subdomains=True,
                    sts_preload=True,
                ),
            ),
        )

        self._lan_only_middleware = traefik.v1alpha1.Middleware(
            "lan-only",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(
                name="lan-only",
                namespace="default",
            ),
            spec=traefik.v1alpha1.MiddlewareSpecArgs(
                ip_white_list=traefik.v1alpha1.MiddlewareSpecIpWhiteListArgs(
                    source_range=["192.168.1.1/24"],
                    # Reject requests with a 404 rather than the default 403.
                    # This is arguably more secure, as we don't reveal the
                    # existence of a page (although the fact that we have a
                    # HTTPS cert for the domain is perhaps revealing...).
                    # Confusingly, this is also super important for Bitwarden.
                    # When off the home network, the mobile app
                    # (understandably) still makes an api call when logging in,
                    # presumably in order to sync the vault.
                    # However, if it gets a 403, the app immediately logs out
                    # (deletes the local encrypted vault and asks you to log in
                    # again). However, since I'm not home, I can't even log in
                    # again! Returning a 404 instead makes the app behave more
                    # nicely: it'll let me use it offline.
                    reject_status_code=404,
                ),
            ),
        )

        # This is a brittle mess. If you are tempted to try to make this less
        # brittle, first see comment in _snowauth_middleware thinking about if
        # we could accomplish this without creating multiple traefik auth
        # middlewares.
        valid_redirect_uris = []
        for access in Access:
            redirect_uri_by_access = {
                Access.INTERNET_UNSECURED: None,
                Access.INTERNET_BEHIND_SSO_RAREMY: "https://snowauth-raremy.snow.jflei.com/_oauth",
                Access.INTERNET_BEHIND_SSO_FAMILY: "https://snowauth-family.snow.jflei.com/_oauth",
                Access.LAN_ONLY: None,
            }
            valid_redirect_uris.append(redirect_uri_by_access[access])

        self._snowauth_keycloak_client = keycloak.openid.Client(
            "snowauth",
            access_type="CONFIDENTIAL",
            client_id="snowauth",
            direct_access_grants_enabled=True,
            realm_id="snow",
            standard_flow_enabled=True,
            valid_post_logout_redirect_uris=["+"],
            valid_redirect_uris=valid_redirect_uris,
        )

        raremy = [
            "jeremyfleischman@gmail.com",
            "rmeresman@gmail.com",
        ]
        family = [
            "mdfleischman@gmail.com",
            "billsmith4804@gmail.com",
        ]
        middlewares_by_access: dict[Access, list[traefik.v1alpha1.Middleware]] = {
            Access.INTERNET_UNSECURED: [],
            Access.INTERNET_BEHIND_SSO_RAREMY: [
                self._snowauth_middleware("raremy", raremy)
            ],
            Access.INTERNET_BEHIND_SSO_FAMILY: [
                self._snowauth_middleware("family", raremy + family)
            ],
            Access.LAN_ONLY: [self._lan_only_middleware],
        }
        self._middlewares_by_access = middlewares_by_access

    def _snowauth_middleware(
        self, desc: str, email_whitelist: list[str]
    ) -> traefik.v1alpha1.Middleware:
        # TODO: rather than creating a traefik auth middleware per interesting
        # subset of users, could we do this in keycloak? That is, have
        # per-application permissions that get rolled up into roles in keycloak
        # (and some check that you have the right permission for the
        # application you're trying to access).
        snowauth_middleware = traefik.v1alpha1.Middleware(
            f"snowauth-{desc}",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(
                name=f"snowauth-{desc}",
                namespace="default",
            ),
            spec=traefik.v1alpha1.MiddlewareSpecArgs(
                forward_auth=traefik.v1alpha1.MiddlewareSpecForwardAuthArgs(
                    address=f"http://snowauth-{desc}.default.svc.cluster.local",
                    auth_response_headers=["X-Forwarded-User"],
                ),
            ),
        )

        deployment = snow_deployment(
            name=f"snowauth-{desc}",
            namespace="default",
            # Upstream https://github.com/thomseddon/traefik-forward-auth appears to no longer be maintained.
            # https://github.com/jordemort/traefik-forward-auth looks like it has received some good love.
            image="ghcr.io/jordemort/traefik-forward-auth:latest@sha256:394f86bff5cc839fac1392f65dd3d4471e827bc29321a4460e7d92042e026599",
            env={
                # "LOG_LEVEL": "debug",
                "COOKIE_DOMAIN": "snow.jflei.com",
                "COOKIE_NAME": f"_forward_auth_{desc}",
                "CSRF_COOKIE_NAME": f"_forward_auth_csrf_{desc}",
                "AUTH_HOST": f"snowauth-{desc}.snow.jflei.com",
                "SECRET": deage(
                    """
                    -----BEGIN AGE ENCRYPTED FILE-----
                    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBqVlU1QlA2Y2NnU2ZQRzlW
                    S2NVbUlnYmlmdEdlcmUvOTREZlZQa3g0TVZRCko4NStEOWh0K0RKVVdFai9qZVF2
                    MWFRbDdlakRYL21pbkVLZzJjTzIvWXcKLS0tIExSc3VQZFNQOWJmUnk1Q1dheU42
                    dGlFcXA0ZEp4WnBiMnBZQmMwRFkvN28KYyCOPk1Y/zaheU+iM2AlAPEJRBPmXFKH
                    06uZDRr9UKf9aK/l6pq4+K2JtJ6G4xloCLPXuqWSdNxXVDcF4zfOGY+79llAoo5q
                    yceWOw==
                    -----END AGE ENCRYPTED FILE-----
                    """
                ),
                "DEFAULT_PROVIDER": "oidc",
                "PROVIDERS_OIDC_ISSUER_URL": "https://keycloak.snow.jflei.com/realms/snow",
                "PROVIDERS_OIDC_CLIENT_ID": self._snowauth_keycloak_client.client_id,
                "PROVIDERS_OIDC_CLIENT_SECRET": self._snowauth_keycloak_client.client_secret,
                "WHITELIST": ",".join(email_whitelist),
                "LOGOUT_REDIRECT": "https://snow.jflei.com",
            },
        )
        service = http_service(deployment, port=4181)
        http_ingress(service)

        return snowauth_middleware

    def _declare_keycloak_realm(self):
        snow = keycloak.Realm(
            "snow",
            access_code_lifespan="1m0s",
            access_code_lifespan_login="30m0s",
            access_code_lifespan_user_action="5m0s",
            access_token_lifespan="5m0s",
            access_token_lifespan_for_implicit_flow="15m0s",
            action_token_generated_by_admin_lifespan="12h0m0s",
            action_token_generated_by_user_lifespan="5m0s",
            browser_flow="browser",
            client_authentication_flow="clients",
            client_session_idle_timeout="0s",
            client_session_max_lifespan="0s",
            default_signature_algorithm="RS256",
            direct_grant_flow="direct grant",
            docker_authentication_flow="docker auth",
            internal_id="snow",
            login_with_email_allowed=True,
            oauth2_device_code_lifespan="10m0s",
            oauth2_device_polling_interval=5,
            offline_session_idle_timeout="720h0m0s",
            offline_session_max_lifespan="1440h0m0s",
            otp_policy=keycloak.RealmOtpPolicyArgs(
                initial_counter=0,
            ),
            realm="snow",
            registration_flow="registration",
            remember_me=True,
            reset_credentials_flow="reset credentials",
            sso_session_idle_timeout="720h0m0s",
            sso_session_idle_timeout_remember_me="0s",
            sso_session_max_lifespan="720h0m0s",
            sso_session_max_lifespan_remember_me="0s",
            web_authn_passwordless_policy=keycloak.RealmWebAuthnPasswordlessPolicyArgs(
                signature_algorithms=["ES256"],
            ),
            web_authn_policy=keycloak.RealmWebAuthnPolicyArgs(
                signature_algorithms=["ES256"],
            ),
            opts=pulumi.ResourceOptions(protect=True),
        )
        return snow

    def middlewares_for_access(
        self, access: Access
    ) -> list[traefik.v1alpha1.Middleware]:
        return self._middlewares_by_access[access]

    def declare_app(
        self,
        name: str,
        namespace: str,
        image: str,
        access: Access,
        port: int = 80,
        env: dict[str, pulumi.Input[str]] = {},
        args: list[str] = [],
        volumes: list[kubernetes.core.v1.VolumeArgs] = [],
        volume_mounts: list[kubernetes.core.v1.VolumeMountArgs] = [],
        working_dir: Optional[str] = None,
        pod_security_context: Optional[kubernetes.core.v1.PodSecurityContextArgs] = None,
    ):
        deployment = snow_deployment(
            name=name,
            namespace=namespace,
            image=image,
            env=env,
            args=args,
            volumes=volumes,
            volume_mounts=volume_mounts,
            working_dir=working_dir,
            pod_security_context=pod_security_context,
        )
        service = http_service(deployment, port=port)

        middlewares = self.middlewares_for_access(access)
        http_ingress(service, traefik_middlewares=middlewares)
