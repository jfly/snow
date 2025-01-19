import pulumi_kubernetes as kubernetes
from pulumi_kubernetes.core.v1 import PodSecurityContextArgs
from .snowauth import Snowauth, Access


class Torrents:
    def __init__(self, snowauth: Snowauth):
        snowauth.declare_app(
            name="torrents",
            namespace="vpn",
            access=Access.INTERNET_BEHIND_SSO_FAMILY,
            image="containers.snow.jflei.com/transmission:latest",
            port=9091,
            pod_security_context=PodSecurityContextArgs(
                # This is similar to the PGID/PUID stuff that the linuxserver folks do:
                # https://github.com/linuxserver/docker-baseimage-alpine/blob/880fac8727d29232d50c17e52ce4dc3da5ec32b0/root/etc/cont-init.d/10-adduser#L6-L7
                # TODO: DRY this number up with all the other places it shows up in our infra.
                run_as_user=0,
                run_as_group=1002,
            ),
            volume_mounts=[
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/mnt/media",
                    name="mnt-media",
                ),
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/root/.config/transmission/stats.json",
                    name="transmission-stats",
                ),
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/root/.config/transmission/resume",
                    name="transmission-resume",
                ),
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/root/.config/transmission/torrents",
                    name="transmission-torrents",
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
                kubernetes.core.v1.VolumeArgs(
                    host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                        path="/state/transmission/stats.json",
                        type="",
                    ),
                    name="transmission-stats",
                ),
                kubernetes.core.v1.VolumeArgs(
                    host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                        path="/state/transmission/resume",
                        type="",
                    ),
                    name="transmission-resume",
                ),
                kubernetes.core.v1.VolumeArgs(
                    host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                        path="/state/transmission/torrents",
                        type="",
                    ),
                    name="transmission-torrents",
                ),
            ],
        )
