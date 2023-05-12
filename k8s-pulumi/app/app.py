from .snowauth import Snowauth
from .radarr import Radarr
from .syncthing import Syncthing
from .whoami import Whoami
from .budget import Budget
from .monitoring import Monitoring
from .miniflux import Miniflux

# from .jfly_laptop import JflyLaptop


def build_app():
    snowauth = Snowauth()
    Radarr(snowauth)
    Syncthing(snowauth)
    Budget(snowauth)
    Whoami(snowauth)
    Monitoring(snowauth)
    Miniflux(snowauth)
    # JflyLaptop()
