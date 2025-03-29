from .snowauth import Snowauth, Access
from .deage import deage
from .util import declare_psql


class Miniflux:
    def __init__(self, snowauth: Snowauth):
        database = declare_psql(
            version="15.2",
            name="minifluxdb",
            namespace="default",
            schema="miniflux",
            admin_username="miniflux",
            admin_password=deage(
                """
                -----BEGIN AGE ENCRYPTED FILE-----
                YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSB3VElSc0E1TE00NFBJM3Na
                S0FZek5rNjJobjlCR3NET29zUkF1RHh4cWhNCmhkZSt2NEdJY2hlTWtKd3RTaXpu
                cUwrTldTazhCaWFaV25Hemh2K0U4NDQKLS0tIDVTZTNrcVRJcXQ1ZnR1bUY3TU81
                YWMxSlM5WGNLSWhJWmxzVHdHR1JjeEkKsoDVG8jKougBKwDO4AqXxmP126sjrnS/
                OKKBVrSI4uS4x6249wueA/YGX7qScut9JhgRNA==
                -----END AGE ENCRYPTED FILE-----
                """
            ),
        )

        snowauth.declare_app(
            name="miniflux",
            # args=["miniflux", "-debug"],
            namespace="default",
            image="miniflux/miniflux:2.2.6",
            port=8080,
            # miniflux has its own login flow -> it should be exposed to
            # the outside world.
            access=Access.INTERNET_UNSECURED,
            env={
                "DATABASE_URL": database.to_db_url("miniflux"),
                "RUN_MIGRATIONS": "1",
                # Fetch video durations from youtube. This seems to be safe to
                # set, and is disabled by default out of FUD about youtube api
                # rate limits. See
                # https://github.com/miniflux/v2/pull/994#issuecomment-780691681
                # for details.
                "FETCH_YOUTUBE_WATCH_TIME": "1",
                # These env vars are only needed when bootstrapping a fresh
                # installation. Once you've got SSO setup for your admin user,
                # you shouldn't need this password anymore.
                # "CREATE_ADMIN": "1",
                # "ADMIN_USERNAME": "jfly",
                # "ADMIN_PASSWORD": REPLACE_ME_WITH_STRING,
                # Enable SSO via keycloak.
                # https://miniflux.app/docs/howto.html#oauth2
                "OAUTH2_PROVIDER": "oidc",
                "OAUTH2_CLIENT_ID": "miniflux",
                "OAUTH2_CLIENT_SECRET": "VF2IgFpEsg9vWF2Ylm1D38XC2o3dowNj",
                "OAUTH2_REDIRECT_URL": "https://miniflux.snow.jflei.com/oauth2/oidc/callback",
                "OAUTH2_OIDC_DISCOVERY_ENDPOINT": "https://keycloak.snow.jflei.com/realms/snow",
            },
        )
