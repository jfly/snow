from .snowauth import SnowAuth
from .radarr import Radarr
from .syncthing import Syncthing
from .whoami import Whoami


def build_app():
    SnowAuth()
    Radarr()
    Syncthing()
    Whoami()
