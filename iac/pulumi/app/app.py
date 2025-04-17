from .snowauth import Snowauth
from .jackett import Jackett
from .radarr import Radarr
from .sonarr import Sonarr
from .bazarr import Bazarr
from .torrents import Torrents
from .speedtest import Speedtest
from .whoami import Whoami
from .budget import Budget
from .miniflux import Miniflux
from .vaultwarden import Vaultwarden
from .invidious import Invidious
from .mosquitto import Mosquitto
from .zigbee2mqtt import Zigbee2Mqtt
from .music import Music
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
    mosquitto = Mosquitto(namespace="default")
    Zigbee2Mqtt(namespace="default", mosquitto=mosquitto, snowauth=snowauth)
    HomeAssistant(namespace="default", snowauth=snowauth, mosquitto=mosquitto)

    Budget(snowauth)
    Whoami(snowauth)
    Miniflux(snowauth)
    Vaultwarden(snowauth)
    Invidious(namespace="default", snowauth=snowauth)
    Nextcloud(snowauth=snowauth)
    # Useful if you really need to run a service somewhere outside of the
    # cluster (perhaps on your laptop) with a valid https cert.
    MiscK8sHttpsProxies(snowauth=snowauth)
    Speedtest(namespace="default", snowauth=snowauth)

    # sync, etc
    Music(snowauth)

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
