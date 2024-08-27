import pulumi_kubernetes as kubernetes
from .snowauth import Snowauth, Access
from .deage import deage


class Vaultwarden:
    def __init__(self, snowauth: Snowauth):
        # We host Vaultwarden under a secret subpath as a form of defense in
        # depth. See
        # https://github.com/dani-garcia/vaultwarden/wiki/Hardening-Guide#hiding-under-a-subdir
        super_secret_subpath = deage(
            """
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBzdXA4YlNBRlNyaEY5RkFs
            TjFCNjVoWFh0MFh4R0JVcGhvT0dWS2pOdms0Ckgwc1EyQmR0WlNlcWo3cUdwb2RD
            MVBBelEzclc5N1BUaXdSUU00WldySFEKLS0tIHJsR05vUHhuYmRRL2dkWlo4Unpt
            OVNsQTlVOFBFMm54LzZUaGtUckx4cVEK9xOT3m0++iI2bF/TLoWAhONVd3/I/zrP
            YjIU9a6kq2+0/9HuOPPdEs9C
            -----END AGE ENCRYPTED FILE-----
            """
        )
        domain = f"https://vw.snow.jflei.com/{super_secret_subpath}"

        snowauth.declare_app(
            name="vw",
            namespace="default",
            image="vaultwarden/server:1.32.0",
            port=80,
            env={
                "DOMAIN": domain,
                # https://github.com/dani-garcia/vaultwarden/wiki/Hardening-Guide#disable-registration-and-optionally-invitations
                "SIGNUPS_ALLOWED": "false",
                "INVITATIONS_ALLOWED": "false",
                # https://github.com/dani-garcia/vaultwarden/wiki/Hardening-Guide#disable-password-hint-display
                "SHOW_PASSWORD_HINT": "false",
            },
            # This is ok to expose "unsecured", as bitwarden has its own login
            # flow.
            access=Access.INTERNET_UNSECURED,
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
        # TODO: consider more forms of backup: https://github.com/dani-garcia/vaultwarden/wiki/Backing-up-your-vault
