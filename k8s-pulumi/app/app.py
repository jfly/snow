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
from .dns import Dns

# from .jfly_laptop import JflyLaptop


def build_app():
    Dns()
    snowauth = Snowauth()
    Radarr(snowauth)
    Syncthing(snowauth)
    Budget(snowauth)
    Whoami(snowauth)
    Monitoring(snowauth)
    Miniflux(snowauth)
    Vaultwarden(snowauth)
    Invidious(namespace="default", snowauth=snowauth)
    NixCache(namespace="default", snowauth=snowauth)
    # JflyLaptop()
