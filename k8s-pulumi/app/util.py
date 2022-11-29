from typing import Dict
from typing import List
import pulumi_kubernetes as kubernetes


def declare_app(
    name: str,
    namespace: str,
    image: str,
    port: int = 80,
    env: Dict[str, str] = {},
    volumes: List[kubernetes.core.v1.VolumeArgs] = [],
    volume_mounts: List[kubernetes.core.v1.VolumeMountArgs] = [],
    sso_protected: bool = True,
):
    if env is None:
        env = {}

    kubernetes.core.v1.Service(
        name,
        metadata=kubernetes.meta.v1.ObjectMetaArgs(
            name=name,
            namespace=namespace,
        ),
        spec=kubernetes.core.v1.ServiceSpecArgs(
            ports=[
                kubernetes.core.v1.ServicePortArgs(
                    name="http",
                    port=80,
                    protocol="TCP",
                    target_port=port,
                ),
            ],
            selector={
                "app": name,
            },
        ),
    )

    kubernetes.apps.v1.Deployment(
        name,
        metadata=kubernetes.meta.v1.ObjectMetaArgs(
            name=name,
            namespace=namespace,
        ),
        spec=kubernetes.apps.v1.DeploymentSpecArgs(
            replicas=1,
            selector=kubernetes.meta.v1.LabelSelectorArgs(
                match_labels={
                    "app": name,
                },
            ),
            template=kubernetes.core.v1.PodTemplateSpecArgs(
                metadata=kubernetes.meta.v1.ObjectMetaArgs(
                    labels={
                        "app": name,
                    },
                ),
                spec=kubernetes.core.v1.PodSpecArgs(
                    containers=[
                        kubernetes.core.v1.ContainerArgs(
                            name=name,
                            env=[
                                kubernetes.core.v1.EnvVarArgs(name=name, value=value)
                                for name, value in env.items()
                            ],
                            image=image,
                            image_pull_policy="Always",
                            volume_mounts=volume_mounts,
                        )
                    ],
                    volumes=volumes,
                ),
            ),
        ),
    )

    extra_annotations = {}
    if sso_protected:
        extra_annotations[
            "traefik.ingress.kubernetes.io/router.middlewares"
        ] = "default-snowauth@kubernetescrd"

    kubernetes.networking.v1.Ingress(
        name,
        metadata=kubernetes.meta.v1.ObjectMetaArgs(
            annotations={
                "cert-manager.io/cluster-issuer": "letsencrypt-prod",
                "traefik.ingress.kubernetes.io/router.entrypoints": "websecure",
                **extra_annotations,
            },
            name=name,
            namespace=namespace,
        ),
        spec=kubernetes.networking.v1.IngressSpecArgs(
            rules=[
                kubernetes.networking.v1.IngressRuleArgs(
                    host=f"{name}.clark.snowdon.jflei.com",
                    http=kubernetes.networking.v1.HTTPIngressRuleValueArgs(
                        paths=[
                            kubernetes.networking.v1.HTTPIngressPathArgs(
                                backend=kubernetes.networking.v1.IngressBackendArgs(
                                    service=kubernetes.networking.v1.IngressServiceBackendArgs(
                                        name=name,
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
                    hosts=[f"{name}.clark.snowdon.jflei.com"],
                    secret_name=f"{name}-tls",
                )
            ],
        ),
    )
