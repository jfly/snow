import pulumi
import pulumi_kubernetes as kubernetes
from typing import Optional
from pulumi_crds import traefik
from .util import snow_deployment
from .util import http_service
from .util import http_ingress
from enum import Enum
from enum import auto


class Access(Enum):
    INTERNET_UNSECURED = auto()
    LAN_ONLY = auto()


class Snowauth:
    def __init__(self):
        # Middleware to add HSTS headers. TODO: actually use this everywhere we
        # do http, or figure out a generic way of enforcing this (perhaps
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
                    source_range=["192.168.28.1/24"],
                ),
            ),
        )

        middlewares_by_access: dict[Access, list[traefik.v1alpha1.Middleware]] = {
            Access.INTERNET_UNSECURED: [],
            Access.LAN_ONLY: [self._lan_only_middleware],
        }
        self._middlewares_by_access = middlewares_by_access

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
        pod_security_context: Optional[
            kubernetes.core.v1.PodSecurityContextArgs
        ] = None,
        container_security_context: Optional[
            kubernetes.core.v1.SecurityContextArgs
        ] = None,
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
            container_security_context=container_security_context,
        )
        service = http_service(deployment, port=port)

        middlewares = self.middlewares_for_access(access)
        http_ingress(service, traefik_middlewares=middlewares)
