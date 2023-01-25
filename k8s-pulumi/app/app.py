from .snowauth import Snowauth
from .radarr import Radarr
from .syncthing import Syncthing
from .whoami import Whoami
from .budget import Budget


def build_app():
    snowauth = Snowauth()
    Radarr(snowauth)
    Syncthing(snowauth)
    Budget(snowauth)
    Whoami(snowauth)
