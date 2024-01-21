import pulumi_kubernetes as kubernetes
from .snowauth import Snowauth, Access


class Jackett:
    def __init__(self, snowauth: Snowauth):
        snowauth.declare_app(
            name="jackett",
            namespace="vpn",
            access=Access.INTERNET_BEHIND_SSO_RAREMY,
            image="ghcr.io/hotio/jackett:latest",
            port=9117,
            env={
                "TZ": "America/Los_Angeles",
                "PUID": "1000",
                "PGID": "1002",
                "UMASK": "002",
            },
            volume_mounts=[
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/config",
                    name="jackett-config",
                ),
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/mnt/media",
                    name="mnt-media",
                ),
            ],
            # TODO: look into k8s persistent volumes for this
            volumes=[
                kubernetes.core.v1.VolumeArgs(
                    host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                        path="/state/jackett-config",
                        type="",
                    ),
                    name="jackett-config",
                ),
                kubernetes.core.v1.VolumeArgs(
                    host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                        path="/mnt/media",
                        type="",
                    ),
                    name="mnt-media",
                ),
            ],
        )
