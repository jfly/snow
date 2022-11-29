from .util import declare_app


class Whoami:
    def __init__(self):
        declare_app(
            name="whoami",
            namespace="default",
            image="containous/whoami:latest",
            port=80,
            # It's ok to expose this to the outside world. Nothing scary here!
            sso_protected=False,
        )
