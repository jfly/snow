import pulumi_kubernetes as kubernetes

from .deage import deage


class SnowAuth:
    def __init__(self):
        kubernetes.core.v1.Service(
            "snowauth",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(
                name="snowauth",
                namespace="default",
            ),
            spec=kubernetes.core.v1.ServiceSpecArgs(
                ports=[
                    kubernetes.core.v1.ServicePortArgs(
                        name="http",
                        port=80,
                        protocol="TCP",
                        target_port=4181,
                    )
                ],
                selector={
                    "app": "snowauth",
                },
            ),
        )

        kubernetes.apps.v1.Deployment(
            "snowauth",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(
                name="snowauth",
                labels={
                    "app": "snowauth",
                },
                namespace="default",
            ),
            spec=kubernetes.apps.v1.DeploymentSpecArgs(
                replicas=1,
                selector=kubernetes.meta.v1.LabelSelectorArgs(
                    match_labels={
                        "app": "snowauth",
                    },
                ),
                template=kubernetes.core.v1.PodTemplateSpecArgs(
                    metadata=kubernetes.meta.v1.ObjectMetaArgs(
                        labels={
                            "app": "snowauth",
                        },
                    ),
                    spec=kubernetes.core.v1.PodSpecArgs(
                        containers=[
                            kubernetes.core.v1.ContainerArgs(
                                name="snowauth",
                                image="thomseddon/traefik-forward-auth:2",
                                ports=[
                                    kubernetes.core.v1.ContainerPortArgs(
                                        container_port=4181,
                                        protocol="TCP",
                                    )
                                ],
                                env=[
                                    kubernetes.core.v1.EnvVarArgs(
                                        name="COOKIE_DOMAIN",
                                        value="clark.snowdon.jflei.com",
                                    ),
                                    kubernetes.core.v1.EnvVarArgs(
                                        name="AUTH_HOST",
                                        value="auth.clark.snowdon.jflei.com",
                                    ),
                                    kubernetes.core.v1.EnvVarArgs(
                                        name="SECRET",
                                        value_from=kubernetes.core.v1.EnvVarSourceArgs(
                                            secret_key_ref=kubernetes.core.v1.SecretKeySelectorArgs(
                                                key="traefik-forward-auth-secret",
                                                name="traefik-forward-auth-secrets",
                                            ),
                                        ),
                                    ),
                                    kubernetes.core.v1.EnvVarArgs(
                                        name="DEFAULT_PROVIDER",
                                        value="oidc",
                                    ),
                                    kubernetes.core.v1.EnvVarArgs(
                                        name="PROVIDERS_OIDC_ISSUER_URL",
                                        value="https://keycloak.clark.snowdon.jflei.com/realms/snow",
                                    ),
                                    kubernetes.core.v1.EnvVarArgs(
                                        name="PROVIDERS_OIDC_CLIENT_ID",
                                        value="snowauth",
                                    ),
                                    kubernetes.core.v1.EnvVarArgs(
                                        name="PROVIDERS_OIDC_CLIENT_SECRET",
                                        value=deage(
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
                                    ),
                                    kubernetes.core.v1.EnvVarArgs(
                                        name="WHITELIST",
                                        value="jeremyfleischman@gmail.com,rmeresman@gmail.com",
                                    ),
                                    kubernetes.core.v1.EnvVarArgs(
                                        name="LOGOUT_REDIRECT",
                                        value="https://clark.snowdon.jflei.com",
                                    ),
                                ],
                            )
                        ],
                    ),
                ),
            ),
        )
