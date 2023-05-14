import pulumi_kubernetes as kubernetes
from .snowauth import Snowauth, Access


class Vaultwarden:
    def __init__(self, snowauth: Snowauth):
        snowauth.declare_app(
            name="vw",
            namespace="default",
            image="vaultwarden/server:latest",
            port=80,
            env={
                "DOMAIN": "https://vw.snow.jflei.com",
                # https://github.com/dani-garcia/vaultwarden/wiki/Disable-registration-of-new-users
                "SIGNUPS_ALLOWED": "false",
            },
            # Out of an abundance of caution, for now we only allow access to
            # Vaultwarden when you're on the local network.
            # https://github.com/dani-garcia/vaultwarden/wiki/Running-a-private-vaultwarden-instance-with-Let%27s-Encrypt-certs
            access=Access.LAN_ONLY,
            volume_mounts=[
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/data",
                    name="data",
                ),
            ],
            # TODO: look into k8s persistent volumes for this
            volumes=[
                kubernetes.core.v1.VolumeArgs(
                    host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                        path="/state/vaultwarden",
                        type="",
                    ),
                    name="data",
                ),
            ],
        )
        # TODO: enable websocket notifications: https://github.com/dani-garcia/vaultwarden/wiki/Enabling-WebSocket-notifications
        # TODO: consider disabling password hints? https://github.com/dani-garcia/vaultwarden/wiki/Hardening-Guide#disable-password-hint-display
        # TODO: consider more forms of backup: https://github.com/dani-garcia/vaultwarden/wiki/Backing-up-your-vault
