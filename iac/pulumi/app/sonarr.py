import pulumi_kubernetes as kubernetes
from .snowauth import Snowauth, Access


class Sonarr:
    def __init__(self, snowauth: Snowauth):
        snowauth.declare_app(
            name="sonarr",
            namespace="vpn",
            access=Access.LAN_ONLY,
            image="ghcr.io/hotio/sonarr:release-4.0.15.2941",
            port=8989,
            env={
                "TZ": "America/Los_Angeles",
                "PUID": "1000",
                "PGID": "1002",
                "UMASK": "002",
                # Sonarr can produce overly long path names when downloading thumbnails.
                # See https://github.com/Sonarr/Sonarr/issues/7782 for details.
                # Set MAX_NAME to a number quite a bit smaller than 255 as a workaround
                "MAX_NAME": "245",
            },
            volume_mounts=[
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/config",
                    name="sonarr-config",
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
                        path="/state/sonarr-config",
                        type="",
                    ),
                    name="sonarr-config",
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
