from .snowauth import Snowauth
from .jackett import Jackett
from .radarr import Radarr
from .sonarr import Sonarr
from .bazarr import Bazarr
from .torrents import Torrents
from .invidious import Invidious
from .snow_state import SnowState
from .dns import Dns
from .misc_k8s_https_proxies import MiscK8sHttpsProxies


def build_app():
    Dns()
    snowauth = Snowauth()
    SnowState()

    # Public services.
    MiscK8sHttpsProxies(snowauth=snowauth)

    # Private services.
    Invidious(namespace="default", snowauth=snowauth)
    Torrents(snowauth)
    Jackett(snowauth)
    Radarr(snowauth)
    Sonarr(snowauth)
    Bazarr(snowauth)
