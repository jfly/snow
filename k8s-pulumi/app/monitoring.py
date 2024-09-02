import pulumi_kubernetes as kubernetes
from .snowauth import Snowauth, Access


class Monitoring:
    def __init__(self, snowauth: Snowauth):
        snowauth.declare_app(
            name="monitoring",
            namespace="default",
            image="louislam/uptime-kuma:1.23.13",
            port=3001,
            volume_mounts=[
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/app/data",
                    name="config",
                ),
            ],
            volumes=[
                # TODO: look into k8s persistent volumes for this
                kubernetes.core.v1.VolumeArgs(
                    host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                        path="/state/uptime-kuma-config",
                        type="",
                    ),
                    name="config",
                ),
            ],
            # uptime kuma has its own login flow -> it should also be exposed to
            # the outside world.
            access=Access.INTERNET_UNSECURED,
        )
