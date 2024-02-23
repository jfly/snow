import dataclasses
import pulumi_kubernetes as kubernetes
from pulumi_kubernetes.core.v1 import ServiceAccount
from pulumi_kubernetes.rbac.v1 import (
    PolicyRuleArgs,
    RoleBinding,
    RoleRefArgs,
    SubjectArgs,
)
import yaml
from typing import Literal, Optional
from .snowauth import Snowauth, Access
from .util import declare_psql
from .deage import deage


@dataclasses.dataclass
class InvidiousConfig:
    """
    See complete list of config options (and explanations) here:
    https://github.com/iv-org/invidious/blob/master/config/config.example.yml
    """

    def to_yaml(self):
        return yaml.dump(dataclasses.asdict(self))

    database_url: str
    check_tables: bool

    external_port: int
    domain: str
    https_only: bool

    use_quic: bool
    log_level: Literal["All", "Trace", "Debug", "Info", "Warn", "Error", "Fatal", "Off"]

    registration_enabled: bool
    login_enabled: bool
    captcha_enabled: bool

    banner: Optional[str]
    hmac_key: str
    default_home: Literal["Popular", "Trending", "Subscriptions", "Playlists"]
    related_videos: bool
    quality: Literal["dash", "hd720", "medium", "small"]

    save_player_pos: bool
    unseen_only: bool
    extend_desc: bool


class Invidious:
    def __init__(self, namespace: str, snowauth: Snowauth):
        self.namespace = namespace

        database = declare_psql(
            version="15.3",
            name="invidious-db",
            namespace=self.namespace,
            schema="invidious",
            admin_username="admin",
            admin_password=deage(
                """
                    -----BEGIN AGE ENCRYPTED FILE-----
                    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBsTWhuYURuUVVScnByK09L
                    V1hoY1FZQ3c4dUI1ZGF0dm84ZTdBZW5JZUFBCjJtVU5za3hRNXkyZXE3ektWZnl1
                    cHJXd1VnSWZFNExVMlZ5WSsxd21sRm8KLS0tIHZWNFJaWnJhdnZWenpxUmxoTndG
                    VnpnZlhwbFFGd1ZLR0ZBbDBDZGVJd28KVM7pwD9U+FMWQxEbb3g0Ybh2SGi+MCWK
                    oxow95rb8UHnKAS0Jzmvhp1vPtf6xFnYOiRTyw==
                    -----END AGE ENCRYPTED FILE-----
                """
            ),
        )

        snowauth.declare_app(
            name="yt",
            namespace=self.namespace,
            image="quay.io/invidious/invidious:latest",
            port=3000,
            # We don't want to expose invidious to the public web. Even with
            # registration disabled, folks can still use it to browse youtube.
            access=Access.INTERNET_BEHIND_SSO_RAREMY,
            env={
                "INVIDIOUS_CONFIG": InvidiousConfig(
                    database_url=database.to_db_url("invidious"),
                    check_tables=True,
                    # Begin public url info.
                    external_port=443,
                    https_only=True,
                    domain="yt.snow.jflei.com",
                    # End public url info.
                    use_quic=True,
                    log_level="Info",
                    registration_enabled=False,
                    login_enabled=True,
                    captcha_enabled=False,
                    banner=None,
                    hmac_key=deage(
                        """
                            -----BEGIN AGE ENCRYPTED FILE-----
                            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSAzU1A5YjRXdUdpNkZqcVRO
                            Qk5XcnpibHhWTVZxRFNBUWduR0FwMXpGWjNNCnIzVjgwWUl0aWo1TTM1dlE2K3BM
                            T2xaWEdaTkMycVF3YWExUTZmK3VTTTgKLS0tIEVVcFhuQUhqY1YxbkVVVEVxQktH
                            NHUwNllRcmRKa3lyS1gvUE0xNysxcUUKWL10MpMAaamypm9d+kGxznKoeMsZenzK
                            DmO7cKs0LANSwHMWV7xlFqPfZhoAv8oPltMr5w==
                            -----END AGE ENCRYPTED FILE-----
                        """
                    ),
                    default_home="Subscriptions",
                    related_videos=False,
                    quality="dash",
                    save_player_pos=True,
                    unseen_only=True,
                    extend_desc=True,
                ).to_yaml(),
            },
        )

        # According to https://docs.invidious.io/installation/#post-install-configuration,
        # we're supposed to restart Invidious frequently:
        #
        # > Because of various issues Invidious must be restarted often, at
        # > least once a day, ideally every hour.
        self.schedule_restart("yt", "@hourly")

    def schedule_restart(self, deployment: str, schedule: str):
        role = kubernetes.rbac.v1.Role(
            f"deployment-restart-{deployment}",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(
                name=f"deployment-restart-{deployment}",
                namespace=self.namespace,
            ),
            rules=[
                PolicyRuleArgs(
                    api_groups=["apps", "extensions"],
                    resources=["deployments"],
                    resource_names=[deployment],
                    verbs=["get", "patch", "list", "watch"],
                ),
            ],
        )
        service_account = ServiceAccount(
            f"deployment-restart-{deployment}",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(
                name=f"deployment-restart-{deployment}",
                namespace=self.namespace,
            ),
        )
        RoleBinding(
            f"deployment-restart-{deployment}",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(
                name=f"deployment-restart-{deployment}",
                namespace=self.namespace,
            ),
            role_ref=RoleRefArgs(
                api_group="rbac.authorization.k8s.io",
                kind="Role",
                name=role._name,
            ),
            subjects=[
                SubjectArgs(
                    kind="ServiceAccount",
                    name=service_account._name,
                    namespace=self.namespace,
                ),
            ],
        )
        kubernetes.batch.v1.CronJob(
            "restart-invidious",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(
                name="restart-invidious",
                namespace=self.namespace,
            ),
            spec=kubernetes.batch.v1.CronJobSpecArgs(
                schedule=schedule,
                job_template=kubernetes.batch.v1.JobTemplateSpecArgs(
                    spec=kubernetes.batch.v1.JobSpecArgs(
                        backoff_limit=1,
                        template=kubernetes.core.v1.PodTemplateSpecArgs(
                            spec=kubernetes.core.v1.PodSpecArgs(
                                containers=[
                                    kubernetes.core.v1.ContainerArgs(
                                        name="kubectl",
                                        image="bitnami/kubectl",
                                        command=[
                                            "kubectl",
                                            "rollout",
                                            "restart",
                                            f"deployment/{deployment}",
                                        ],
                                    )
                                ],
                                service_account_name=service_account._name,
                                restart_policy="Never",
                            ),
                        ),
                    )
                ),
            ),
        )
