import pulumi_kubernetes as kubernetes


class Radarr:
    def __init__(self):
        kubernetes.core.v1.Service(
            "vpn/radarr",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(
                name="radarr",
                namespace="vpn",
            ),
            spec=kubernetes.core.v1.ServiceSpecArgs(
                ports=[
                    kubernetes.core.v1.ServicePortArgs(
                        name="http",
                        port=80,
                        protocol="TCP",
                        target_port=7878,
                    )
                ],
                selector={
                    "app": "radarr",
                },
            ),
        )

        kubernetes.apps.v1.Deployment(
            "vpn/radarr",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(
                name="radarr",
                namespace="vpn",
            ),
            spec=kubernetes.apps.v1.DeploymentSpecArgs(
                replicas=1,
                selector=kubernetes.meta.v1.LabelSelectorArgs(
                    match_labels={
                        "app": "radarr",
                    },
                ),
                template=kubernetes.core.v1.PodTemplateSpecArgs(
                    metadata=kubernetes.meta.v1.ObjectMetaArgs(
                        labels={
                            "app": "radarr",
                        },
                    ),
                    spec=kubernetes.core.v1.PodSpecArgs(
                        containers=[
                            kubernetes.core.v1.ContainerArgs(
                                env=[
                                    kubernetes.core.v1.EnvVarArgs(
                                        name="TZ",
                                        value="America/Los_Angeles",
                                    ),
                                    kubernetes.core.v1.EnvVarArgs(
                                        name="PUID",
                                        value="1000",
                                    ),
                                    kubernetes.core.v1.EnvVarArgs(
                                        name="PGID",
                                        value="1002",
                                    ),
                                    kubernetes.core.v1.EnvVarArgs(
                                        name="UMASK",
                                        value="002",
                                    ),
                                ],
                                image="cr.hotio.dev/hotio/radarr",
                                image_pull_policy="Always",
                                name="radarr",
                                volume_mounts=[
                                    kubernetes.core.v1.VolumeMountArgs(
                                        mount_path="/config",
                                        name="radarr-config",
                                    ),
                                    kubernetes.core.v1.VolumeMountArgs(
                                        mount_path="/mnt/media",
                                        name="mnt-media",
                                    ),
                                ],
                            )
                        ],
                        # TODO: look into k8s persistent volumes for this
                        volumes=[
                            kubernetes.core.v1.VolumeArgs(
                                host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                                    path="/state/radarr-config",
                                    type="",
                                ),
                                name="radarr-config",
                            ),
                            kubernetes.core.v1.VolumeArgs(
                                host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                                    path="/mnt/media",
                                    type="",
                                ),
                                name="mnt-media",
                            ),
                        ],
                    ),
                ),
            ),
        )

        kubernetes.networking.v1.Ingress(
            "vpn/radarr",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(
                annotations={
                    "cert-manager.io/cluster-issuer": "letsencrypt-prod",
                    "traefik.ingress.kubernetes.io/router.entrypoints": "websecure",
                    "traefik.ingress.kubernetes.io/router.middlewares": "default-snowauth@kubernetescrd",
                },
                name="radarr",
                namespace="vpn",
            ),
            spec=kubernetes.networking.v1.IngressSpecArgs(
                rules=[
                    kubernetes.networking.v1.IngressRuleArgs(
                        host="radarr.clark.snowdon.jflei.com",
                        http=kubernetes.networking.v1.HTTPIngressRuleValueArgs(
                            paths=[
                                kubernetes.networking.v1.HTTPIngressPathArgs(
                                    backend=kubernetes.networking.v1.IngressBackendArgs(
                                        service=kubernetes.networking.v1.IngressServiceBackendArgs(
                                            name="radarr",
                                            port=kubernetes.networking.v1.ServiceBackendPortArgs(
                                                number=80,
                                            ),
                                        ),
                                    ),
                                    path="/",
                                    path_type="Prefix",
                                )
                            ],
                        ),
                    )
                ],
                tls=[
                    kubernetes.networking.v1.IngressTLSArgs(
                        hosts=["radarr.clark.snowdon.jflei.com"],
                        secret_name="radarr-tls",
                    )
                ],
            ),
        )
