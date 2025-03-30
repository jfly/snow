from .util import http_ingress, http_service, snow_deployment
from pulumi_crds import traefik
import pulumi_kubernetes as kubernetes


class LegacyRedirects:
    def __init__(self):
        self._clark_snowdon_to_snow_redirect()

    def _clark_snowdon_to_snow_redirect(self):
        clark_to_snow_redirect = traefik.v1alpha1.Middleware(
            resource_name="clark-to-snow-redirect",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(
                name="clark-to-snow-redirect",
                namespace="default",
            ),
            spec=traefik.v1alpha1.MiddlewareSpecArgs(
                redirect_regex=traefik.v1alpha1.MiddlewareSpecRedirectRegexArgs(
                    regex="^https://(.*).clark.snowdon.jflei.com/(.*)$",
                    replacement="https://$1.snow.jflei.com/$2",
                    permanent=True,
                ),
            ),
        )
        blackhole_service = self._blackhole_service()
        http_ingress(
            service=blackhole_service,
            base_url="https://*.clark.snowdon.jflei.com",
            traefik_middlewares=[clark_to_snow_redirect],
        )

    def _blackhole_service(self) -> kubernetes.core.v1.Service:
        """
        Just returns some service with undefined behavior. The details shouldn't
        matter as it shouldn't receive any traffic.

        Useful if you just want to declare an ingress with some useful
        annotations/middleware. I don't know if there's a less weird way of
        accomplishing this.
        """
        deployment = snow_deployment(
            name="blackhole",
            namespace="default",
            image="containous/whoami:latest",
        )
        return http_service(deployment, port=80)
