from .snowauth import Snowauth
from .jackett import Jackett
from .radarr import Radarr
from .sonarr import Sonarr
from .bazarr import Bazarr
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
    Jackett(snowauth)
    Radarr(snowauth)
    Sonarr(snowauth)
    Bazarr(snowauth)
