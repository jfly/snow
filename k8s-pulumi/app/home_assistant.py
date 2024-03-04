import pulumi_kubernetes as kubernetes
from .snowauth import Snowauth, Access
from .util import declare_psql
from .deage import deage


class HomeAssistant:
    def __init__(self, namespace: str, snowauth: Snowauth):
        self.namespace = namespace

        declare_psql(
            version="14.3",
            name="home-assistant-db",
            namespace=self.namespace,
            schema="homeassistant_db",
            admin_username="admin",
            admin_password=deage(
                """
                    -----BEGIN AGE ENCRYPTED FILE-----
                    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBEbWJra1FwZzVuaFlxQTh4
                    Wm9URnRuRUVRVWJya0hMUmNKZlZiMVJ6NHlZCm1tMkJnOTFoQ0lvVjdXSGl2SXUz
                    d3RUZWRsTXBRRnV5WldYN0RDWkw0d2cKLS0tIG4yMnA4aXRieVhNcWFnQUtzdHIx
                    a2FFSWFLRmZ6aWFRTzVHRGFPU1d0STQKPCwsKlBAihSRzz8RBZK4YhNcQ0NFXMTc
                    wYsX0TR2DDfx46hb+fobinryyIHqq/BFV0gkvQ==
                    -----END AGE ENCRYPTED FILE-----
                """
            ),
        )

        snowauth.declare_app(
            name="home-assistant",
            namespace=self.namespace,
            image="homeassistant/home-assistant:2024.2.2",
            port=8123,
            # Home Assistant has its own authentication mechanism, so it's ok
            # to expose to the world.
            access=Access.INTERNET_UNSECURED,
            env={
                "TZ": "America/Los_Angeles",
            },
            container_security_context=kubernetes.core.v1.SecurityContextArgs(
                # I haven't found a better way to give permission to use the character device.
                # See https://www.reddit.com/r/kubernetes/comments/13j791x/zigbee2mqtt_container_with_usb_device_but_not/
                privileged=True,
            ),
            volume_mounts=[
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/config",
                    name="ha-config",
                ),
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/dev/ttyACM0",
                    name="ttyacm",
                ),
            ],
            # TODO: look into k8s persistent volumes for this
            volumes=[
                kubernetes.core.v1.VolumeArgs(
                    host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                        path="/state/ha-config",
                        type="",
                    ),
                    name="ha-config",
                ),
                kubernetes.core.v1.VolumeArgs(
                    host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                        path="/dev/ttyACM0",
                        type="CharDevice",
                    ),
                    name="ttyacm",
                ),
            ],
        )
