from .snowauth import SnowAuth
from .radarr import Radarr
from .syncthing import Syncthing


def build_app():
    SnowAuth()
    Radarr()
    Syncthing()
