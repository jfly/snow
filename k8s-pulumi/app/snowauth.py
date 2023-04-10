import pulumi_kubernetes as kubernetes
from typing import Optional
from pulumi_crds import traefik
from .util import snow_deployment
from .util import http_service
from .util import http_ingress
from .deage import deage


class Snowauth:
    def __init__(self):
        self.snowauth_middleware = traefik.v1alpha1.Middleware(
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

        self.declare_app(
            name="snowauth",
            namespace="default",
            image="thomseddon/traefik-forward-auth:2",
            port=4181,
            env={
                "COOKIE_DOMAIN": "clark.snowdon.jflei.com",
                "AUTH_HOST": "snowauth.clark.snowdon.jflei.com",
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
                "PROVIDERS_OIDC_ISSUER_URL": "https://keycloak.clark.snowdon.jflei.com/realms/snow",
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
                "WHITELIST": "jeremyfleischman@gmail.com,rmeresman@gmail.com,mdfleischman@gmail.com",
                # TODO: figure out how to limit permissions for some users "WHITELIST": "jeremyfleischman@gmail.com,rmeresman@gmail.com,mdfleischman@gmail.com",
                "LOGOUT_REDIRECT": "https://clark.snowdon.jflei.com",
            },
        )

    def declare_app(
        self,
        name: str,
        namespace: str,
        image: str,
        port: int = 80,
        env: dict[str, str] = {},
        args: list[str] = [],
        volumes: list[kubernetes.core.v1.VolumeArgs] = [],
        volume_mounts: list[kubernetes.core.v1.VolumeMountArgs] = [],
        working_dir: Optional[str] = None,
        sso_protected: bool = True,
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

        middlewares = []
        if sso_protected:
            middlewares.append(self.snowauth_middleware)
        http_ingress(service, traefik_middlewares=middlewares)
