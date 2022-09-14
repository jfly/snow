import pulumi_kubernetes as kubernetes
from .util import declare_app


class Syncthing:
    def __init__(self):
        declare_app(
            name="syncthing",
            namespace="default",
            image="lscr.io/linuxserver/syncthing",
            port=8384,
            extra_ports=[
                kubernetes.core.v1.ServicePortArgs(
                    name="listening-port-tcp",
                    port=22000,
                    protocol="TCP",
                    target_port=22000,
                ),
                kubernetes.core.v1.ServicePortArgs(
                    name="listening-port-udp",
                    port=22000,
                    protocol="UDP",
                    target_port=22000,
                ),
                kubernetes.core.v1.ServicePortArgs(
                    name="protocol-discovery",
                    port=21027,
                    protocol="UDP",
                    target_port=21027,
                ),
            ],
            env={
                "TZ": "America/Los_Angeles",
                "PUID": "1000",
                "PGID": "1002",
                "UMASK": "002",
            },
            volume_mounts=[
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/config",
                    name="syncthing-config",
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
                        path="/state/syncthing-config",
                        type="",
                    ),
                    name="syncthing-config",
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
