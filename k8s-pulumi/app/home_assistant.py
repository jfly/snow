import pulumi_kubernetes as kubernetes
from .snowauth import Snowauth, Access
from .util import declare_psql
from .deage import deage


class HomeAssistant:
    def __init__(self, namespace: str, snowauth: Snowauth):
        self.namespace = namespace

        database = declare_psql(
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
            image="homeassistant/home-assistant:2023.3.1",
            port=8123,
            # Home Assistant has its own authentication mechanism, so it's ok
            # to expose to the world.
            access=Access.INTERNET_UNSECURED,
            env={
                "TZ": "America/Los_Angeles",
            },
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
