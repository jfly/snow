from .snowauth import Snowauth
from .jackett import Jackett
from .radarr import Radarr
from .sonarr import Sonarr
from .bazarr import Bazarr
from .torrents import Torrents
from .syncthing import Syncthing
from .whoami import Whoami
from .budget import Budget
from .monitoring import Monitoring
from .miniflux import Miniflux
from .vaultwarden import Vaultwarden
from .invidious import Invidious
from .mosquitto import Mosquitto
from .nix_cache import NixCache
from .nextcloud import Nextcloud
from .snow_web import SnowWeb
from .home_assistant import HomeAssistant
from .snow_state import SnowState
from .dns import Dns
from .legacy_redirects import LegacyRedirects
from .misc_k8s_https_proxies import MiscK8sHttpsProxies


def build_app():
    Dns()
    snowauth = Snowauth()
    SnowState()

    LegacyRedirects()

    SnowWeb(snowauth)
    Mosquitto(namespace="default")
    HomeAssistant(namespace="default", snowauth=snowauth)
    Syncthing(snowauth)
    Budget(snowauth)
    Whoami(snowauth)
    Monitoring(snowauth)
    Miniflux(snowauth)
    Vaultwarden(snowauth)
    Invidious(namespace="default", snowauth=snowauth)
    NixCache(namespace="default", snowauth=snowauth)
    Nextcloud(snowauth=snowauth)
    # Useful if you really need to run a service somewhere outside of the
    # cluster (perhaps on your laptop) with a valid https cert.
    MiscK8sHttpsProxies(snowauth=snowauth)

    Torrents(snowauth)
    Jackett(snowauth)
    Radarr(snowauth)
    Sonarr(snowauth)
    Bazarr(snowauth)

    ###
    ### Some stuff that's useful to turn on as necessary, but not stuff I want running 24/7
    ###

    # An example of using a helm chart and dealing with ingress. Also, using
    # Pulumi to declare an s3 bucket.
    # from .baserow import Baserow; Baserow(namespace="default", snowauth=snowauth)
