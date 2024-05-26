import pulumi_kubernetes as kubernetes
from .deage import deage
from .snowauth import Snowauth
from .snowauth import Access


class Music:
    def __init__(self, snowauth: Snowauth):
        # https://www.navidrome.org/docs/installation/docker/
        snowauth.declare_app(
            name="music",
            namespace="default",
            image="deluan/navidrome:latest",
            port=4533,
            # navidrome has its own authentication mechanism.
            # It does support [Reverse proxy
            # authentication](https://www.navidrome.org/docs/usage/security/#reverse-proxy-authentication),
            # but it's only useful for the webapp.
            access=Access.INTERNET_UNSECURED,
            env={
                # "ND_LOGLEVEL": "debug",
                "ND_BASEURL": "https://music.snow.jflei.com",
                # TODO: figure out scrobbling
                # "ND_LISTENBRAINZ_BASEURL": "http://maloja.default.svc.cluster.local/apis/listenbrainz",
            },
            volume_mounts=[
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/data",
                    name="navidrome-data",
                ),
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/music",
                    name="music",
                    read_only=True,
                ),
            ],
            # TODO: look into k8s persistent volumes for this
            volumes=[
                kubernetes.core.v1.VolumeArgs(
                    host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                        path="/state/navidrome-data",
                        type="",
                    ),
                    name="navidrome-data",
                ),
                kubernetes.core.v1.VolumeArgs(
                    host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                        path="/mnt/media/music",
                        type="",
                    ),
                    name="music",
                ),
            ],
        )

        snowauth.declare_app(
            name="maloja",
            namespace="default",
            image="krateng/maloja:3.2.2",
            port=42010,
            access=Access.INTERNET_BEHIND_SSO_RAREMY,
            env={
                "MALOJA_FORCE_PASSWORD": deage(
                    """
                    -----BEGIN AGE ENCRYPTED FILE-----
                    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSAreWlXendyK0VhbklzejBz
                    WW5HMkRxTVAyaGF4SFNZY2t3aEMxNFZtbnpJCm5GQm1zMUszMlBpZHhLLzkxN0VV
                    MVQxWWJlREpIS0w0YU5CeFIyUnlOcXcKLS0tIGxGM1V5dGFma1ZnNC91bXhoMTM2
                    WWdtZzZjVWNzVCtRNW5PQzQ1NnJMTG8KZ54JyZg9qIY1zUUoRi3mXv8T+enLGf4c
                    8nBthT39m/4N6vf7L2eCSbHHKi7hjKY+hX6jaA==
                    -----END AGE ENCRYPTED FILE-----
                    """
                ),
                "MALOJA_DATA_DIRECTORY": "/data",
            },
            volume_mounts=[
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/data",
                    name="maloja-data",
                ),
            ],
            # TODO: look into k8s persistent volumes for this
            volumes=[
                kubernetes.core.v1.VolumeArgs(
                    host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                        path="/state/maloja-data",
                        type="",
                    ),
                    name="maloja-data",
                ),
            ],
        )
