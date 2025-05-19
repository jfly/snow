import pulumi_kubernetes as kubernetes
from .util import http_ingress
from .util import http_service
from .util import snow_deployment
from .snowauth import Snowauth
from .snowauth import Access


class Budget:
    def __init__(self, snowauth: Snowauth):
        hledger_base_url = "https://budget.snow.jflei.com/ledger"
        hledger_web_deployment = self._snow_budget_deployment(
            name="ledger",
            namespace="default",
            args=[
                "hledger-web",
                "--serve",
                "--allow",
                "view",
                "@budget/budget.args",
                "--host=0.0.0.0",
                "--port=5000",
                f"--base-url={hledger_base_url}",
            ],
        )
        hledger_web_service = http_service(hledger_web_deployment, port=5000)
        http_ingress(
            hledger_web_service,
            traefik_middlewares=snowauth.middlewares_for_access(
                Access.INTERNET_BEHIND_SSO_RAREMY
            ),
            base_url=hledger_base_url,
            # hledger-web (actually yesod) is a bit weird when you give it a
            # base-url with a path: it'll generate links correctly, but it
            # expects a proxy in front that'll remove the prefix before the
            # request arrives. See
            # https://github.com/simonmichael/hledger/issues/1562 and
            # https://github.com/yesodweb/yesod/issues/1792 for more details.
            strip_path=True,
        )

        budget_deployment = self._snow_budget_deployment(
            name="budget",
            namespace="default",
            args=[
                "manman-run-site",
                "--hostname=0.0.0.0",
                "--port=5000",
            ],
        )
        budget_service = http_service(budget_deployment, port=5000)
        http_ingress(
            budget_service,
            traefik_middlewares=snowauth.middlewares_for_access(
                Access.INTERNET_BEHIND_SSO_RAREMY
            ),
        )

        kubernetes.batch.v1.CronJob(
            "snow-budget-daily-import",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(
                name="snow-budget-daily-import",
            ),
            spec=kubernetes.batch.v1.CronJobSpecArgs(
                schedule="5 4 * * *",
                job_template=kubernetes.batch.v1.JobTemplateSpecArgs(
                    spec=kubernetes.batch.v1.JobSpecArgs(
                        backoff_limit=2,
                        template=kubernetes.core.v1.PodTemplateSpecArgs(
                            spec=kubernetes.core.v1.PodSpecArgs(
                                containers=[
                                    kubernetes.core.v1.ContainerArgs(
                                        command=["just", "fetch-and-commit"],
                                        image="clark.ec:5000/snow-budget-import:latest",
                                        name="import",
                                        working_dir="/manmanmon",
                                        volume_mounts=[
                                            kubernetes.core.v1.VolumeMountArgs(
                                                mount_path="/manmanmon",
                                                name="manmanmon",
                                            ),
                                            # Also include the remote so a git push can work.
                                            kubernetes.core.v1.VolumeMountArgs(
                                                mount_path="/state/git/manmanmon.git",
                                                name="manmanmon-gitremote",
                                            ),
                                        ],
                                        env=to_k8s_env_var_args(
                                            {
                                                # The app expects this variable to be set. It normally *is* set
                                                # by bash, but there's no bash process involved when running
                                                # this docker container.
                                                # There are other ways of doing this (probably best practice
                                                # would be to explicitly set all the config this application
                                                # needs), but this is a kind of weird project, and I think I'm
                                                # ok with it.
                                                "PWD": "/manmanmon",
                                                # Set some env vars so git commit works.
                                                "GIT_AUTHOR_NAME": "clark",
                                                "GIT_AUTHOR_EMAIL": "clark@jflei.com",
                                                "GIT_COMMITTER_NAME": "clark",
                                                "GIT_COMMITTER_EMAIL": "clark@jflei.com",
                                                # Reset the git working
                                                # directory if necessary (this
                                                # lets us recover from previous
                                                # failed imports).
                                                "MANMAN_RESET_REPO_IF_NECESSARY": "1",
                                            }
                                        ),
                                    )
                                ],
                                restart_policy="Never",
                                volumes=[
                                    kubernetes.core.v1.VolumeArgs(
                                        host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                                            path="/state/git/manmanmon",
                                            type="",
                                        ),
                                        name="manmanmon",
                                    ),
                                    # Also include the remote so a git push can work.
                                    kubernetes.core.v1.VolumeArgs(
                                        host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                                            path="/state/git/manmanmon.git",
                                            type="",
                                        ),
                                        name="manmanmon-gitremote",
                                    ),
                                ],
                            ),
                        ),
                    )
                ),
            ),
        )

    def _snow_budget_deployment(self, name: str, namespace: str, args: list[str]):
        image = "clark.ec:5000/snow-budget:latest"
        return snow_deployment(
            name=name,
            namespace=namespace,
            args=args,
            image=image,
            env={
                "LEDGER_FILE": "/manmanmon/all-years.journal",
            },
            working_dir="/manmanmon",
            volume_mounts=[
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/manmanmon",
                    name="manmanmon",
                ),
            ],
            volumes=[
                kubernetes.core.v1.VolumeArgs(
                    host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                        path="/state/git/manmanmon",
                        type="",
                    ),
                    name="manmanmon",
                ),
            ],
        )


def to_k8s_env_var_args(environ) -> list[kubernetes.core.v1.EnvVarArgs]:
    return [kubernetes.core.v1.EnvVarArgs(name=k, value=v) for k, v in environ.items()]
