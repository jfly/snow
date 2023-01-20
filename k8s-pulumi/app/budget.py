import pulumi_kubernetes as kubernetes
from .util import declare_app


class Budget:
    def __init__(self):
        image = "containers.clark.snowdon.jflei.com/snow-hledger:2myd7sf4yp9ng0wgs7zv2fd39s8v6n6m"
        declare_app(
            name="ledger",
            namespace="default",
            image=image,
            port=5000,
            args=[
                "just",
                "run",
                "--host=0.0.0.0",
                "--port=5000",
                "--base-url=https://ledger.clark.snowdon.jflei.com",
            ],
            working_dir="/manmanmon",
            env={
                # The app expects this variable to be set. It normally *is* set
                # by bash, but there's no bash process involved when running
                # this docker container.
                # There are other ways of doing this (probably best practice
                # would be to explicitly set all the config this application
                # needs), but this is a kind of weird project, and I think I'm
                # ok with it.
                "PWD": "/manmanmon",
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
                "just",
                "run-site-prod",
                "--hostname=0.0.0.0",
                "--port=5000",
            ],
            working_dir="/manmanmon",
            env={
                # The app expects this variable to be set. It normally *is* set
                # by bash, but there's no bash process involved when running
                # this docker container.
                # There are other ways of doing this (probably best practice
                # would be to explicitly set all the config this application
                # needs), but this is a kind of weird project, and I think I'm
                # ok with it.
                "PWD": "/manmanmon",
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
