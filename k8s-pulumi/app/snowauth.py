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
    INTERNET_BEHIND_SSO = auto()
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

        self._snowauth_middleware = traefik.v1alpha1.Middleware(
            "snowauth",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(
                name="snowauth",
                namespace="default",
            ),
            spec=traefik.v1alpha1.MiddlewareSpecArgs(
                forward_auth=traefik.v1alpha1.MiddlewareSpecForwardAuthArgs(
                    address="http://snowauth.default.svc.cluster.local",
                    auth_response_headers=["X-Forwarded-User"],
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
                ),
            ),
        )

        self.declare_app(
            name="snowauth",
            namespace="default",
            image="thomseddon/traefik-forward-auth:2",
            port=4181,
            access=Access.INTERNET_BEHIND_SSO,
            env={
                # "LOG_LEVEL": "debug",
                "COOKIE_DOMAIN": "snow.jflei.com",
                "AUTH_HOST": "snowauth.snow.jflei.com",
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
                "PROVIDERS_OIDC_CLIENT_ID": "snowauth",
                "PROVIDERS_OIDC_CLIENT_SECRET": deage(
                    """
                    -----BEGIN AGE ENCRYPTED FILE-----
                    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBITU1jZkhTeU5zRVd6eG1y
                    b3FKVVBFMFdHdnF2dnptZmVUZWFjMVIyb3lVCnNrQmt1bmpOTmRuTkx5bkxpMEdt
                    RXVJbElxaGZjYnRZRFRWdWNoVkVXSjgKLS0tIG80S1NHR29MYm04V0VJUXA5OUFw
                    UXlRUUhUazVTbUo4bkFqMURLUjdlVjQK3uVLJMRcBpSz2f6xr1eFCneTJRlLYm+c
                    H3DT+BQ4s2vizRtcs7wghE1x0kAQJPsQVoSp3RLFnn8akyKs3ePtDA==
                    -----END AGE ENCRYPTED FILE-----
                    """
                ),
                "WHITELIST": "jeremyfleischman@gmail.com,rmeresman@gmail.com,mdfleischman@gmail.com,billsmith4804@gmail.com",
                # TODO: figure out how to limit permissions for some users "WHITELIST": "jeremyfleischman@gmail.com,rmeresman@gmail.com,mdfleischman@gmail.com",
                "LOGOUT_REDIRECT": "https://snow.jflei.com",
            },
        )

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
        return {
            Access.INTERNET_UNSECURED: [],
            Access.INTERNET_BEHIND_SSO: [self._snowauth_middleware],
            Access.LAN_ONLY: [self._lan_only_middleware],
        }[access]

    def declare_app(
        self,
        name: str,
        namespace: str,
        image: str,
        access: Access,
        port: int = 80,
        env: dict[str, str] = {},
        args: list[str] = [],
        volumes: list[kubernetes.core.v1.VolumeArgs] = [],
        volume_mounts: list[kubernetes.core.v1.VolumeMountArgs] = [],
        working_dir: Optional[str] = None,
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
        )
        service = http_service(deployment, port=port)

        middlewares = self.middlewares_for_access(access)
        http_ingress(service, traefik_middlewares=middlewares)
