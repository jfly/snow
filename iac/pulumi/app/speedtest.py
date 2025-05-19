from .snowauth import Snowauth, Access


class Speedtest:
    def __init__(self, namespace: str, snowauth: Snowauth):
        snowauth.declare_app(
            name="speedtest",
            namespace=namespace,
            access=Access.INTERNET_UNSECURED,
            image="clark.ec:5000/speedtest-go:latest",
            port=8989,
        )
