import dataclasses
from typing import cast
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
from .util import declare_psql, snow_deployment, http_service, http_ingress
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

    signature_server: str
    po_token: str
    visitor_data: str


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

        signature_server = self._declare_inv_sig_helper()

        name = "yt"
        namespace = self.namespace
        image = "quay.io/invidious/invidious:latest"
        port = 3000

        deployment = snow_deployment(
            name=name,
            namespace=namespace,
            image=image,
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
                    default_home="Subscriptions",
                    related_videos=False,
                    quality="dash",
                    save_player_pos=True,
                    unseen_only=True,
                    extend_desc=True,
                    # https://docs.invidious.io/installation/#post-install-configuration
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
                    # Configure the signature server.
                    # To generate `po_token` and `visitor_data`:
                    #
                    #   ```
                    #   kubectl run yt-session-gen --attach --rm --image=quay.io/invidious/youtube-trusted-session-generator
                    #   ```
                    signature_server=signature_server,
                    po_token=deage(
                        """
                        -----BEGIN AGE ENCRYPTED FILE-----
                        YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSArUWNxcmw4ZGpoTEhWRFFD
                        MHFFUXNhYnh4REtTdlJVSmxWME1GcnBVa2hZClpodGNYajUzaHNHK2NpUUxwTE5T
                        TFlMdlQ2WVZrSkMrV2tsYVFUZDFaY0UKLS0tIFRhZDdHOWwzdUFBOEo2SlVPYlEv
                        aUFoU1U5T0Vka2NYdlBtamZLUmJwQUUK0J09k6qO+7JaD4XAs+B3zLoW16zqmWXI
                        dBn92OS5e1JsforVz3QWBi2vK3g0WZmcpqxTGfWm4jc/eM9o6MNdMqXZM6tjy1ju
                        yF1H9zyAfodiVduj4mUkPiFHI74xc705KtkEKsaKgvYi7OXWTqvq11g/Wy2ATPII
                        scfQrGwQM7OOxNZ42BJ3hFv/GkrxvKdVT+8CPN8v1KT3EgZ4h+E30zVkNvL7gFtt
                        PoZyZKVxEwzYQTRBx/u+AgwH1kKgZZVz
                        -----END AGE ENCRYPTED FILE-----
                        """
                    ),
                    visitor_data=deage(
                        """
                        -----BEGIN AGE ENCRYPTED FILE-----
                        YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBtcTRneCtPSE4yM0VacERM
                        TFFzUWZ0cDhpdGZEUjBYZHZEWWdwb2tnTzJRCngwdGZiRThJZ0dTUFVyS2ovYTc4
                        Nmc5UmVXWUhaLzNDRVFqRWZqRk1ydEEKLS0tIGV1NEJLT05Iei9meXNpa0lPczhx
                        UW13NFAxZGRQYzhGajRLZnA0b0l0OWMKsyDIERtznvwKdBQYEob50h3p2eAwbbRI
                        bk5PExinqum9DgV2EtX0gaArOafL50t+0hf79DIUfUUQKmSui9ho5LOoSf1T0oRO
                        ybcB4w1f1YY=
                        -----END AGE ENCRYPTED FILE-----
                        """
                    ),
                ).to_yaml(),
            },
        )
        service = http_service(deployment, port=port)

        http_ingress(
            service,
            traefik_middlewares=snowauth.middlewares_for_access(
                # We don't want to expose invidious to the public web. Even with
                # registration disabled, folks can still use it to browse youtube.
                access=Access.INTERNET_BEHIND_SSO_RAREMY,
            ),
        )

        http_ingress(
            service,
            base_url="https://yt-lan.snow.jflei.com",
            ingress_name="yt-lan",
            traefik_middlewares=snowauth.middlewares_for_access(
                # We don't want to expose invidious to the public web. Even with
                # registration disabled, folks can still use it to browse youtube.
                access=Access.LAN_ONLY,
            ),
        )

        # According to https://docs.invidious.io/installation/#post-install-configuration,
        # we're supposed to restart Invidious frequently:
        #
        # > Because of various issues Invidious must be restarted often, at
        # > least once a day, ideally every hour.
        self.schedule_restart("yt", "@hourly")

    def _declare_inv_sig_helper(self) -> str:
        name = "inv-sig-helper"
        port = 12999
        deployment = snow_deployment(
            name=name,
            namespace=self.namespace,
            image="quay.io/invidious/inv-sig-helper:latest",
            args=["--tcp", f"0.0.0.0:{port}"],
            env={
                "RUST_LOG": "info",
            },
        )
        deployment_metadata = cast(
            kubernetes.meta.v1.ObjectMetaArgs, deployment.metadata
        )
        kubernetes.core.v1.Service(
            deployment._name,
            metadata=kubernetes.meta.v1.ObjectMetaArgs(
                name=deployment_metadata.name,
                namespace=deployment_metadata.namespace,
            ),
            spec=kubernetes.core.v1.ServiceSpecArgs(
                ports=[
                    kubernetes.core.v1.ServicePortArgs(
                        name="inv-sig-helper",
                        port=port,
                        protocol="TCP",
                        target_port=port,
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
        return f"{name}:{port}"

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
