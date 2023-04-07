import pulumi_kubernetes as kubernetes
from .snowauth import Snowauth


class Monitoring:
    def __init__(self, snowauth: Snowauth):
        snowauth.declare_app(
            name="monitoring",
            namespace="default",
            image="louislam/uptime-kuma:1.21.2",
            port=3001,
            volume_mounts=[
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/app/data",
                    name="config",
                ),
            ],
            # TODO: look into k8s persistent volumes for this
            volumes=[
                kubernetes.core.v1.VolumeArgs(
                    host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                        path="/state/uptime-kuma-config",
                        type="",
                    ),
                    name="config",
                ),
            ],
            # uptime kuma has its own login flow + it should also be exposed to
            # the outside world.
            sso_protected=False,
        )
