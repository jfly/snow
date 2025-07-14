from .snowauth import Snowauth
from .jackett import Jackett
from .radarr import Radarr
from .sonarr import Sonarr
from .bazarr import Bazarr
from .torrents import Torrents
from .speedtest import Speedtest
from .miniflux import Miniflux
from .vaultwarden import Vaultwarden
from .invidious import Invidious
from .snow_state import SnowState
from .dns import Dns
from .misc_k8s_https_proxies import MiscK8sHttpsProxies


def build_app():
    Dns()
    snowauth = Snowauth()
    SnowState()

    Miniflux(snowauth)
    Vaultwarden(snowauth)
    Invidious(namespace="default", snowauth=snowauth)
    # Useful if you really need to run a service somewhere outside of the
    # cluster (perhaps on your laptop) with a valid https cert.
    MiscK8sHttpsProxies(snowauth=snowauth)
    Speedtest(namespace="default", snowauth=snowauth)

    Torrents(snowauth)
    Jackett(snowauth)
    Radarr(snowauth)
    Sonarr(snowauth)
    Bazarr(snowauth)
