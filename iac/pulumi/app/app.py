from .dns import Dns
from .misc_k8s_https_proxies import MiscK8sHttpsProxies


def build_app():
    Dns()
    MiscK8sHttpsProxies()
