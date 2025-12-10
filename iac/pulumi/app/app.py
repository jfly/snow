from .snowauth import Snowauth
from .dns import Dns
from .misc_k8s_https_proxies import MiscK8sHttpsProxies


def build_app():
    Dns()

    snowauth = Snowauth()
    MiscK8sHttpsProxies(snowauth)
