import pulumi_kubernetes as kubernetes
from .snowauth import Snowauth, Access


class Torrents:
    def __init__(self, snowauth: Snowauth):
        snowauth.declare_app(
            name="torrents",
            namespace="vpn",
            access=Access.INTERNET_BEHIND_SSO_RAREMY,
            image="containers.snow.jflei.com/transmission:latest",
            port=9091,
            volume_mounts=[
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/mnt/media",
                    name="mnt-media",
                ),
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/state/transmission/stats.json",
                    name="transmission-stats",
                ),
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/state/transmission/resume",
                    name="transmission-resume",
                ),
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/state/transmission/torrents",
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
                        path="/root/.config/transmission-daemon/stats.json",
                        type="",
                    ),
                    name="transmission-stats",
                ),
                kubernetes.core.v1.VolumeArgs(
                    host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                        path="/root/.config/transmission-daemon/resume",
                        type="",
                    ),
                    name="transmission-resume",
                ),
                kubernetes.core.v1.VolumeArgs(
                    host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                        path="/root/.config/transmission-daemon/torrents",
                        type="",
                    ),
                    name="transmission-torrents",
                ),
            ],
        )
