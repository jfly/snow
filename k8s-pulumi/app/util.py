from typing import Optional
import dataclasses
from typing import cast
import pulumi_kubernetes as kubernetes
from typing import cast
from pulumi_crds import traefik
from pulumi import Output
from urllib.parse import urlparse


def snow_deployment(
    name: str,
    namespace: str,
    image: str,
    env: Optional[dict[str, str]] = None,
    args: Optional[list[str]] = None,
    volumes: Optional[list[kubernetes.core.v1.VolumeArgs]] = None,
    volume_mounts: Optional[list[kubernetes.core.v1.VolumeMountArgs]] = None,
    working_dir: Optional[str] = None,
) -> kubernetes.apps.v1.Deployment:
    if env is None:
        env = {}

    if args is None:
        args = []

    if volumes is None:
        volumes = []

    if volume_mounts is None:
        volume_mounts = []

    return kubernetes.apps.v1.Deployment(
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
                            args=args,
                            working_dir=working_dir,
                        )
                    ],
                    volumes=volumes,
                ),
            ),
        ),
    )


def http_service(
    deployment: kubernetes.apps.v1.Deployment,
    port: int,
) -> kubernetes.core.v1.Service:
    deployment_metadata = cast(kubernetes.meta.v1.ObjectMetaArgs, deployment.metadata)
    return kubernetes.core.v1.Service(
        deployment._name,
        metadata=kubernetes.meta.v1.ObjectMetaArgs(
            name=deployment_metadata.name,
            namespace=deployment_metadata.namespace,
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
            selector=cast(
                kubernetes.meta.v1.LabelSelectorArgs,
                cast(kubernetes.apps.v1.DeploymentSpecArgs, deployment.spec).selector,
            ).match_labels,
        ),
    )


def format_traefik_middlewares(middlewares: list[traefik.v1alpha1.Middleware]):
    traefik_middlewares = []

    for middleware in middlewares:
        middleware_metadata = cast(
            kubernetes.meta.v1.ObjectMetaArgs, middleware.metadata
        )
        traefik_middlewares.append(
            Output.concat(
                middleware_metadata.namespace,
                "-",
                middleware_metadata.name,
                "@kubernetescrd",
            )
        )

    return Output.all(*traefik_middlewares).apply(lambda mws: ",".join(mws))


def http_ingress(
    service: kubernetes.core.v1.Service,
    traefik_middlewares: Optional[list[traefik.v1alpha1.Middleware]] = None,
    base_url: Optional[str] = None,
    strip_path: bool = False,
):
    """
    Expose the given service, with optional Traefik middlewares.

    If base_url is specified, then that hostname will be used, otherwise a
    hostname will be generated from the given service's name.

    If strip_path is specified, then base_url must also be specified and have a
    non-empty path (such as http://example.com/some-path). With strip_path
    enabled, the path (in this case, /some-path) will be removed before the
    request gets forwarded to the underlying service. This is useful to nest
    some services under a subpath. For example, hledger-web's url generation
    logic can be changed, but not it's url parsing logic. In other words, you
    can tell it "hey, whenever you generate a link prefix it with this path",
    but you can't tell it to actually respond to those urls, you actually need
    a proxy in front of it to manipulate the path. I personally find this to be
    a sort of odd, half-baked behavior, but it seems to be intentional,
    :shrug:. See https://github.com/simonmichael/hledger/issues/1562 and
    https://github.com/yesodweb/yesod/issues/1792 for more details.
    """
    name = service._name
    service_metadata = cast(kubernetes.meta.v1.ObjectMetaArgs, service.metadata)

    if base_url is None:
        host = f"{name}.snow.jflei.com"
        path = "/"
    else:
        parsed = urlparse(base_url)
        host = parsed.hostname
        assert host is not None
        path = parsed.path
        assert path is not None
        if path == "":
            path = "/"

    if traefik_middlewares is None:
        traefik_middlewares = []

    if strip_path:
        assert path != "/", "Must specify a path if strip_path is enabled"
        middleware_name = f"strip-{name}-{path.replace('/', '')}"
        traefik_middlewares.append(
            traefik.v1alpha1.Middleware(
                middleware_name,
                metadata=kubernetes.meta.v1.ObjectMetaArgs(
                    name=middleware_name,
                    namespace=service_metadata.namespace,
                ),
                spec=traefik.v1alpha1.MiddlewareSpecArgs(
                    strip_prefix=traefik.v1alpha1.MiddlewareSpecStripPrefixArgs(
                        prefixes=[path],
                    ),
                ),
            )
        )

    extra_annotations = {}
    if len(traefik_middlewares) > 0:
        extra_annotations[
            "traefik.ingress.kubernetes.io/router.middlewares"
        ] = format_traefik_middlewares(traefik_middlewares)

    return kubernetes.networking.v1.Ingress(
        name,
        metadata=kubernetes.meta.v1.ObjectMetaArgs(
            annotations={
                "cert-manager.io/cluster-issuer": "letsencrypt-prod",
                "traefik.ingress.kubernetes.io/router.entrypoints": "websecure",
                **extra_annotations,
            },
            name=service_metadata.name,
            namespace=service_metadata.namespace,
        ),
        spec=kubernetes.networking.v1.IngressSpecArgs(
            rules=[
                kubernetes.networking.v1.IngressRuleArgs(
                    host=host,
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
                                path=path,
                                path_type="Prefix",
                            )
                        ],
                    ),
                )
            ],
            tls=[
                kubernetes.networking.v1.IngressTLSArgs(
                    hosts=[host],
                    secret_name=f"{name}-tls",
                )
            ],
        ),
    )


@dataclasses.dataclass
class Database:
    name: str
    namespace: str
    admin_username: str
    admin_password: str
    schema: str

    def hostname(self, fqdn: bool = False):
        return f"{self.name}.{self.namespace}.svc.cluster.local" if fqdn else self.name

    def to_db_url(self, schema: str, fqdn: bool = False):
        return f"postgres://{self.admin_username}:{self.admin_password}@{self.hostname(fqdn=fqdn)}/{schema}?sslmode=disable"


def declare_psql(
    name: str,
    namespace: str,
    schema: str,
    admin_username: str,
    admin_password: str,
    version: str,
) -> Database:
    deployment = snow_deployment(
        name=name,
        namespace=namespace,
        image=f"postgres:{version}",
        env={
            "POSTGRES_USER": admin_username,
            "POSTGRES_PASSWORD": admin_password,
            "POSTGRES_DB": schema,
        },
        volume_mounts=[
            kubernetes.core.v1.VolumeMountArgs(
                mount_path="/var/lib/postgresql/data",
                name="db",
            ),
        ],
        # TODO: look into k8s persistent volumes for this
        volumes=[
            kubernetes.core.v1.VolumeArgs(
                host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                    path=f"/state/psql/{name}",
                    type="",
                ),
                name="db",
            ),
        ],
    )
    kubernetes.core.v1.Service(
        name,
        metadata=kubernetes.meta.v1.ObjectMetaArgs(
            name=name,
            namespace=namespace,
        ),
        spec=kubernetes.core.v1.ServiceSpecArgs(
            ports=[
                kubernetes.core.v1.ServicePortArgs(
                    name="psql",
                    port=5432,
                    protocol="TCP",
                ),
            ],
            selector=cast(
                kubernetes.meta.v1.LabelSelectorArgs,
                cast(kubernetes.apps.v1.DeploymentSpecArgs, deployment.spec).selector,
            ).match_labels,
        ),
    )
    return Database(
        name=name,
        namespace=namespace,
        admin_username=admin_username,
        admin_password=admin_password,
        schema=schema,
    )
