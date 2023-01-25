import pulumi_kubernetes as kubernetes
from .snowauth import Snowauth


class Syncthing:
    def __init__(self, snowauth: Snowauth):
        # Note: I had to manually edit this application's config to set
        # `insecureSkipHostcheck` to true:
        # https://docs.syncthing.net/users/config.html#config-option-gui.insecureskiphostcheck
        # Urg.
        #
        # I also configured the device address via the UI, the resulting value in config.xml is:
        #   <address>tcp://clark.snowdon.jflei.com:22000</address>
        #
        # I also set the syncthing device's name to "snow".
        snowauth.declare_app(
            name="syncthing",
            namespace="default",
            image="lscr.io/linuxserver/syncthing",
            port=8384,
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

        # Expose non-http ports that syncthing needs to work without a relay.
        kubernetes.core.v1.Service(
            "syncthing-discovery",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(
                namespace="default",
            ),
            spec=kubernetes.core.v1.ServiceSpecArgs(
                type="LoadBalancer",
                selector={
                    "app": "syncthing",
                },
                ports=[
                    # Note: This port also needs to be exposed to the outside
                    # world via port forwarding. That's configured at
                    # http://strider/Advanced_VirtualServer_Content.asp
                    # I wonder if there's some clever way of wiring up k3s with
                    # the router's port forwarding configuration...
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
                    # This is for LAN discovery, it does not need to be exposed to the outside world.
                    kubernetes.core.v1.ServicePortArgs(
                        name="protocol-discovery",
                        port=21027,
                        protocol="UDP",
                        target_port=21027,
                    ),
                ],
            ),
        )
