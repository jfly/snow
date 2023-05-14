import pulumi_kubernetes as k8s


class JflyLaptop:
    """
    Create a service without a selector and explicitly add an endpoint to get
    traffic to my laptop.
    (This is sometimes useful for rapid prototyping something that needs a real
    certificate or needs to be exposed to the outside world.)
    For more information about how this works, see:
     - https://kubernetes.io/docs/concepts/services-networking/service/#services-without-selectors
     - https://kristhecodingunicorn.com/post/k8s_proxy_svc/
    """

    def __init__(self):
        # Ingress resource
        k8s.networking.v1.Ingress(
            "nextcloud",
            metadata={
                "annotations": {
                    "cert-manager.io/cluster-issuer": "letsencrypt-prod",
                    "traefik.ingress.kubernetes.io/router.entrypoints": "websecure",
                },
                "name": "nextcloud",
            },
            spec={
                "tls": [
                    {
                        "hosts": ["nextcloud.snow.jflei.com"],
                        "secretName": "nextcloud-tls",
                    }
                ],
                "rules": [
                    {
                        "host": "nextcloud.snow.jflei.com",
                        "http": {
                            "paths": [
                                {
                                    "path": "/",
                                    "pathType": "Prefix",
                                    "backend": {
                                        "service": {
                                            "name": "pattern-laptop",
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
            "pattern-laptop",
            metadata={
                "name": "pattern-laptop",
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
        #   name: pattern-laptop-1
        #   labels:
        #     kubernetes.io/service-name: pattern-laptop
        # addressType: IPv4
        # ports:
        #   - name: ''
        #     appProtocol: http
        #     protocol: TCP
        #     port: 11000
        # endpoints:
        #   - addresses:
        #       - "192.168.1.9"  # pattern (jfly laptop)
        k8s.core.v1.Endpoints(
            "pattern-laptop",
            metadata={
                "name": "pattern-laptop",
            },
            subsets=[
                {
                    "addresses": [
                        {
                            "ip": "192.168.1.9",  # pattern (jfly laptop)
                        }
                    ],
                    "ports": [
                        {
                            "port": 11000,
                        }
                    ],
                }
            ],
        )
