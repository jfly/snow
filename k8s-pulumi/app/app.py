from .snowauth import Snowauth
from .radarr import Radarr
from .syncthing import Syncthing
from .whoami import Whoami
from .budget import Budget
from .monitoring import Monitoring
from .miniflux import Miniflux
from .vaultwarden import Vaultwarden
from .invidious import Invidious
from .nix_cache import NixCache
from .nextcloud import Nextcloud
from .snow_state import SnowState
from .dns import Dns
from .legacy_redirects import LegacyRedirects


def build_app():
    Dns()
    snowauth = Snowauth()
    snow_state = SnowState()

    LegacyRedirects()

    Radarr(snowauth)
    Syncthing(snowauth)
    Budget(snowauth)
    Whoami(snowauth)
    Monitoring(snowauth)
    Miniflux(snowauth)
    Vaultwarden(snowauth)
    Invidious(namespace="default", snowauth=snowauth)
    NixCache(namespace="default", snowauth=snowauth)
    Nextcloud(snowauth=snowauth)

    ###
    ### Some stuff that's useful to turn on as necessary, but not stuff I want running 24/7
    ###

    # An example of using a helm chart and dealing with ingress. Also, using
    # Pulumi to declare an s3 bucket.
    # from .baserow import Baserow; Baserow(namespace="default", snowauth=snowauth)

    # Useful if you really need to run a service locally with a valid https
    # cert.
    # from .jfly_laptop import JflyLaptop; JflyLaptop()
