import pulumi_kubernetes as kubernetes
from .util import declare_app


class Budget:
    def __init__(self):
        image = "containers.clark.snowdon.jflei.com/snow-budget:latest"
        declare_app(
            name="ledger",
            namespace="default",
            image=image,
            port=5000,
            args=[
                "hledger-web",
                "--serve",
                "--capabilities",
                "view",
                "@budget/budget.args",
                "--host=0.0.0.0",
                "--port=5000",
                "--base-url=https://ledger.clark.snowdon.jflei.com",
            ],
            working_dir="/manmanmon",
            env={
                "LEDGER_FILE": "/manmanmon/all-years.journal",
            },
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
        declare_app(
            name="budget",
            namespace="default",
            image=image,
            port=5000,
            args=[
                "manman-run-site",
                "--hostname=0.0.0.0",
                "--port=5000",
            ],
            working_dir="/manmanmon",
            env={
                "LEDGER_FILE": "/manmanmon/all-years.journal",
            },
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

        kubernetes.batch.v1.CronJob(
            "snow-budget-daily-import",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(
                name="snow-budget-daily-import",
            ),
            spec=kubernetes.batch.v1.CronJobSpecArgs(
                schedule="@daily",
                job_template=kubernetes.batch.v1.JobTemplateSpecArgs(
                    spec=kubernetes.batch.v1.JobSpecArgs(
                        backoff_limit=2,
                        template=kubernetes.core.v1.PodTemplateSpecArgs(
                            spec=kubernetes.core.v1.PodSpecArgs(
                                containers=[
                                    kubernetes.core.v1.ContainerArgs(
                                        command=["just", "fetch-and-commit"],
                                        image="containers.clark.snowdon.jflei.com/snow-budget-import:latest",
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


def to_k8s_env_var_args(environ):
    return [kubernetes.core.v1.EnvVarArgs(name=k, value=v) for k, v in environ.items()]
