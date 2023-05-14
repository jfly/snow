import pulumi_kubernetes as kubernetes
from .snowauth import Snowauth, deage
from .util import snow_deployment
import dataclasses
from typing import cast


@dataclasses.dataclass
class Database:
    hostname: str
    admin_username: str
    admin_password: str

    def to_db_url(self, schema: str):
        return f"postgres://{self.admin_username}:{self.admin_password}@{self.hostname}/{schema}?sslmode=disable"


class Miniflux:
    def __init__(self, snowauth: Snowauth):
        database = self.declare_psql(
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
            namespace="default",
            image="miniflux/miniflux:2.0.43",
            port=8080,
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
            # miniflux has its own login flow + it should be exposed to
            # the outside world.
            sso_protected=False,
        )

    def declare_psql(
        self,
        name: str,
        namespace: str,
        schema: str,
        admin_username: str,
        admin_password: str,
    ):
        deployment = snow_deployment(
            name=name,
            namespace=namespace,
            image="postgres:15.2",
            env={
                "POSTGRES_USER": admin_username,
                "POSTGRES_PASSWORD": admin_password,
                "POSTGRES_DB": schema,
            },
            volume_mounts=[
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/var/lib/postgresql/data",
                    name="db",
                ),
            ],
            # TODO: look into k8s persistent volumes for this
            volumes=[
                kubernetes.core.v1.VolumeArgs(
                    host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                        path=f"/state/psql/{name}",
                        type="",
                    ),
                    name="db",
                ),
            ],
        )
        kubernetes.core.v1.Service(
            name,
            metadata=kubernetes.meta.v1.ObjectMetaArgs(
                name=name,
                namespace=namespace,
            ),
            spec=kubernetes.core.v1.ServiceSpecArgs(
                ports=[
                    kubernetes.core.v1.ServicePortArgs(
                        name="psql",
                        port=5432,
                        protocol="TCP",
                    ),
                ],
                selector=cast(
                    kubernetes.meta.v1.LabelSelectorArgs,
                    cast(
                        kubernetes.apps.v1.DeploymentSpecArgs, deployment.spec
                    ).selector,
                ).match_labels,
            ),
        )
        return Database(
            hostname=f"{name}.default.svc.cluster.local",
            admin_username=admin_username,
            admin_password=admin_password,
        )
