import pulumi_kubernetes as kubernetes
from .snowauth import Snowauth
from .snowauth import Access
from .util import snow_deployment
from .util import http_service
from .util import http_ingress


class SnowWeb:
    def __init__(self, snowauth: Snowauth):
        deployment = snow_deployment(
            name="snow-web",
            namespace="default",
            image="clark.ec:5000/snow-web:latest",
            volume_mounts=[
                # Only expose the movies, shows, and torrents subdirectories.
                # This works, but we might want to consider restructuring
                # /mnt/media to put these in a shared subdirectory instead (and
                # use that as an opportunity to think carefully about
                # filesystem permissions). For example, dallben doesn't need
                # access to all the files it currently has access to.
                kubernetes.core.v1.VolumeMountArgs(
                    name="mnt-media",
                    sub_path="movies",
                    mount_path="/mnt/media/movies",
                ),
                kubernetes.core.v1.VolumeMountArgs(
                    name="mnt-media",
                    sub_path="shows",
                    mount_path="/mnt/media/shows",
                ),
                kubernetes.core.v1.VolumeMountArgs(
                    name="mnt-media",
                    sub_path="torrents",
                    mount_path="/mnt/media/torrents",
                ),
            ],
            # TODO: look into k8s persistent volumes for this
            volumes=[
                kubernetes.core.v1.VolumeArgs(
                    host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                        path="/mnt/media",
                        type="",
                    ),
                    name="mnt-media",
                ),
            ],
        )
        service = http_service(deployment, port=80)

        http_ingress(
            service,
            ingress_name="snow-web-root",
            traefik_middlewares=snowauth.middlewares_for_access(
                Access.INTERNET_BEHIND_SSO_FAMILY
            ),
            base_url="https://snow.jflei.com",
        )
        http_ingress(
            service,
            ingress_name="snow-web-media",
            traefik_middlewares=snowauth.middlewares_for_access(
                Access.INTERNET_BEHIND_SSO_FAMILY
            ),
            base_url="https://media.snow.jflei.com",
        )
        http_ingress(
            service,
            ingress_name="snow-web-tnoodle-redirect",
            traefik_middlewares=snowauth.middlewares_for_access(
                Access.INTERNET_UNSECURED
            ),
            base_url="https://www.tnoodle.tk",
        )

        # TODO: unrecognized subdomains (such as
        # https://unknown.snow.jflei.com/) currently fail ssl validation (but
        # do return a 404 if you ignore the cert error). can/should we get
        # those passing? or would it be better to remove our wildcard dns entry
        # in favor of more targeted dns?
