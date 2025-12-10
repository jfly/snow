import pulumi_kubernetes as kubernetes
from .snowauth import Snowauth, Access


class Bazarr:
    def __init__(self, snowauth: Snowauth):
        snowauth.declare_app(
            name="bazarr",
            namespace="vpn",
            access=Access.LAN_ONLY,
            image="ghcr.io/hotio/bazarr:release-1.5.3",
            port=6767,
            env={
                "TZ": "America/Los_Angeles",
                "PUID": "1000",
                "PGID": "1002",
                "UMASK": "002",
            },
            volume_mounts=[
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/config",
                    name="bazarr-config",
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
                        path="/state/bazarr-config",
                        type="",
                    ),
                    name="bazarr-config",
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
