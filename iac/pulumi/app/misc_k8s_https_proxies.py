import pulumi_kubernetes as k8s
from .util import http_ingress


class MiscK8sHttpsProxies:
    def __init__(self):
        self._add_proxy(
            "jellyfin",
            destination_ip="192.168.28.172",  # `fflewddur.ec` (keep this in sync with `packages/strider-openwrt/files/etc/config/dhcp`)
            destination_port=80,
        )

        self._add_proxy(
            "healthcheck",
            destination_ip="192.168.28.172",  # `fflewddur.ec` (keep this in sync with `packages/strider-openwrt/files/etc/config/dhcp`)
            destination_port=80,
        )

        self._add_proxy(
            "speedtest",
            destination_ip="192.168.28.172",  # `fflewddur.ec` (keep this in sync with `packages/strider-openwrt/files/etc/config/dhcp`)
            destination_port=80,
        )

    def _add_proxy(
        self,
        name: str,
        destination_ip: str,
        destination_port: int,
    ):
        """
        Create a service without a selector and explicitly add an endpoint to get
        traffic to the destination.
        (This is sometimes useful for rapidly prototyping something that needs a real
        certificate or needs to be exposed to the outside world.)
        For more information about how this works, see:
         - https://kubernetes.io/docs/concepts/services-networking/service/#services-without-selectors
         - https://kristhecodingunicorn.com/post/k8s_proxy_svc/
        """
        # Service resource
        service = k8s.core.v1.Service(
            name,
            metadata={
                "name": name,
            },
            spec=k8s.core.v1.ServiceSpecArgs(
                ports=[
                    k8s.core.v1.ServicePortArgs(
                        port=80,
                        target_port=11000,
                    ),
                ],
            ),
        )

        # Endpoints resource
        k8s.core.v1.Endpoints(
            name,
            metadata={
                "name": name,
            },
            subsets=[
                {
                    "addresses": [
                        {
                            "ip": destination_ip,
                        }
                    ],
                    "ports": [
                        {
                            "port": destination_port,
                        }
                    ],
                }
            ],
        )

        # Ingress resource
        http_ingress(
            service,
            ingress_name=name,
            base_url=f"https://{name}.snow.jflei.com",
        )
