import pulumi_kubernetes as k8s
from .snowauth import Access, Snowauth
from .util import http_ingress


class MiscK8sHttpsProxies:
    def __init__(self, snowauth: Snowauth):
        self._snowauth = snowauth

        # Feel free to enable/tweak as necessary.
        # self._add_proxy(
        #     "jflysolaptop",
        #     destination_ip="192.168.1.182",  # pattern.lan (jfly laptop)
        #     destination_port=8080,
        # )

        self._add_proxy(
            "pr-tracker",
            access=Access.INTERNET_UNSECURED,
            destination_ip="192.168.1.110",  # clark.lan
            destination_port=7000,  # see clark/pr-tracker.nix
        )

        self._add_proxy(
            "lloyd",
            access=Access.INTERNET_BEHIND_SSO_RAREMY,
            destination_ip="192.168.1.242",  # lloyd.lan
            destination_port=80,
        )

        # TODO: figure out how to get websockets working with Kodi's Chorus2 web ui.
        # The UI is hardcoded to use port 9090 for websockets:
        #  https://github.com/xbmc/chorus2/blob/f9f376930fd544e86b1dd3c0dc5f8999031d73c5/src/js/app.coffee#L8
        # It shouldn't be this way, see discussion on https://github.com/xbmc/chorus2/issues/133.
        self._add_proxy(
            "kodi",
            access=Access.INTERNET_BEHIND_SSO_RAREMY,
            destination_ip="192.168.1.163",  # dallben.lan (keep this in sync with openwrt/strider/files/etc/config/dhcp)
            destination_port=8080,
        )

        self._add_proxy(
            "ospi",
            access=Access.INTERNET_BEHIND_SSO_RAREMY,
            destination_ip="192.168.1.197",  # ospi.lan (keep this in sync with openwrt/strider/files/etc/config/dhcp)
            destination_port=8080,
        )

    def _add_proxy(
        self,
        name: str,
        destination_ip: str,
        destination_port: int,
        access: Access,
    ):
        """
        Create a service without a selector and explicitly add an endpoint to get
        traffic to the destination.
        (This is sometimes useful for rapid prototyping something that needs a real
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

        # Ingress resource
        traefik_middlewares = []
        if access is not None:
            traefik_middlewares += self._snowauth.middlewares_for_access(access)
        http_ingress(
            service,
            ingress_name=name,
            traefik_middlewares=traefik_middlewares,
            base_url=f"https://{name}.snow.jflei.com",
        )
