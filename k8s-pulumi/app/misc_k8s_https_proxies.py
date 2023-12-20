import pulumi_kubernetes as k8s


class MiscK8sHttpsProxies:
    def __init__(self):
        # Feel free to enable/tweak as necessary.
        # self._add_proxy(
        #     "jflysolaptop",
        #     destination_ip="192.168.1.182",  # pattern (jfly laptop)
        #     destination_port=8080,
        # )

        self._add_proxy(
            "pr-tracker",
            destination_ip="192.168.1.110",  # clark
            destination_port=7000,  # see clark/pr-tracker.nix
        )

    def _add_proxy(self, name: str, destination_ip: str, destination_port: int):
        """
        Create a service without a selector and explicitly add an endpoint to get
        traffic to the destination.
        (This is sometimes useful for rapid prototyping something that needs a real
        certificate or needs to be exposed to the outside world.)
        For more information about how this works, see:
         - https://kubernetes.io/docs/concepts/services-networking/service/#services-without-selectors
         - https://kristhecodingunicorn.com/post/k8s_proxy_svc/
        """
        # Ingress resource
        k8s.networking.v1.Ingress(
            name,
            metadata={
                "annotations": {
                    "cert-manager.io/cluster-issuer": "letsencrypt-prod",
                    "traefik.ingress.kubernetes.io/router.entrypoints": "websecure",
                },
                "name": name,
            },
            spec={
                "tls": [
                    {
                        "hosts": [f"{name}.snow.jflei.com"],
                        "secretName": f"{name}-tls",
                    }
                ],
                "rules": [
                    {
                        "host": f"{name}.snow.jflei.com",
                        "http": {
                            "paths": [
                                {
                                    "path": "/",
                                    "pathType": "Prefix",
                                    "backend": {
                                        "service": {
                                            "name": name,
                                            "port": {
                                                "number": 80,
                                            },
                                        },
                                    },
                                }
                            ],
                        },
                    }
                ],
            },
        )

        # Service resource
        k8s.core.v1.Service(
            name,
            metadata={
                "name": name,
            },
            spec={
                "ports": [
                    {
                        "port": 80,
                        "targetPort": 11000,
                    }
                ],
            },
        )

        # Endpoints resource
        #
        # For some reason the traefik ingress controller doesn't seem to work with
        # EndpointSlice, so we have to use Endpoints.
        # ---
        # apiVersion: discovery.k8s.io/v1
        # kind: EndpointSlice
        # metadata:
        #   name: {name}
        #   labels:
        #     kubernetes.io/service-name: {name}
        # addressType: IPv4
        # ports:
        #   - name: ''
        #     appProtocol: http
        #     protocol: TCP
        #     port: 11000
        # endpoints:
        #   - addresses:
        #       - {destination_ip}
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
