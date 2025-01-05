from .util import http_ingress
import pulumi_kubernetes as k8s
from .snowauth import Snowauth, Access


class NixCache:
    def __init__(self, namespace: str, snowauth: Snowauth):
        self.namespace = namespace

        # Endpoints resource
        #
        # For some reason the traefik ingress controller doesn't seem to work
        # with EndpointSlice, so we have to use Endpoints. See
        # iac/pulumi/app/misc_k8s_https_proxies.py for another example of this
        # problem.
        k8s.core.v1.Endpoints(
            "pattern-laptop",
            metadata={
                "name": "cache",
            },
            subsets=[
                {
                    "addresses": [
                        {
                            "ip": "192.168.1.172",  # fflewddur.ec
                        }
                    ],
                    "ports": [
                        {
                            "port": 5000,
                        }
                    ],
                }
            ],
        )

        # Service resource
        service = k8s.core.v1.Service(
            "cache",
            metadata={
                "name": "cache",
            },
            spec={
                "ports": [
                    {
                        "port": 80,
                        "targetPort": 5000,
                    }
                ],
            },
        )

        middlewares = snowauth.middlewares_for_access(access=Access.LAN_ONLY)
        http_ingress(service, traefik_middlewares=middlewares)
