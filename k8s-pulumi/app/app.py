from .snowauth import SnowAuth
from .radarr import Radarr
from .syncthing import Syncthing
from .whoami import Whoami
from .budget import Budget


def build_app():
    SnowAuth()
    Radarr()
    Syncthing()
    Budget()
    Whoami()
