from .snowauth import SnowAuth
from .radarr import Radarr


def build_app():
    SnowAuth()
    Radarr()
