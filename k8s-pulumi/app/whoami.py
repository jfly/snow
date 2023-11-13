from .snowauth import Snowauth, Access


class Whoami:
    def __init__(self, snowauth: Snowauth):
        snowauth.declare_app(
            name="whoami",
            namespace="default",
            image="containous/whoami:latest",
            port=80,
            # It's ok to expose this to the outside world. Nothing scary here!
            access=Access.INTERNET_UNSECURED,
        )
        snowauth.declare_app(
            name="whoami-sso",
            namespace="default",
            image="containous/whoami:latest",
            port=80,
            access=Access.INTERNET_BEHIND_SSO_FAMILY,
        )
