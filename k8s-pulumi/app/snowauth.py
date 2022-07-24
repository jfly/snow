import pulumi
import pulumi_kubernetes as kubernetes

from pulumi_crds import traefik


from .deage import deage


class SnowAuth:
    def __init__(self):
        traefik.v1alpha1.Middleware(
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

        kubernetes.networking.v1.Ingress(
            "auth",
            api_version="networking.k8s.io/v1",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(
                name="auth",
                namespace="default",
                annotations={
                    "cert-manager.io/cluster-issuer": "letsencrypt-prod",
                    "traefik.ingress.kubernetes.io/router.entrypoints": "websecure",
                    "traefik.ingress.kubernetes.io/router.middlewares": "default-snowauth@kubernetescrd",
                },
            ),
            spec=kubernetes.networking.v1.IngressSpecArgs(
                rules=[
                    kubernetes.networking.v1.IngressRuleArgs(
                        host="auth.clark.snowdon.jflei.com",
                        http=kubernetes.networking.v1.HTTPIngressRuleValueArgs(
                            paths=[
                                kubernetes.networking.v1.HTTPIngressPathArgs(
                                    path="/",
                                    path_type="Prefix",
                                    backend=kubernetes.networking.v1.IngressBackendArgs(
                                        service=kubernetes.networking.v1.IngressServiceBackendArgs(
                                            name="snowauth",
                                            port=kubernetes.networking.v1.ServiceBackendPortArgs(
                                                number=80,
                                            ),
                                        ),
                                    ),
                                )
                            ],
                        ),
                    )
                ],
                tls=[
                    kubernetes.networking.v1.IngressTLSArgs(
                        hosts=["auth.clark.snowdon.jflei.com"],
                        secret_name="auth-tls",
                    )
                ],
            ),
            opts=pulumi.ResourceOptions(protect=True),
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
                                        value=deage(
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
