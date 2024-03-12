import pulumi_kubernetes as kubernetes
from typing import cast
from pulumi_kubernetes.core.v1 import (
    ConfigMap,
    ConfigMapVolumeSourceArgs,
    PodSecurityContextArgs,
    Secret,
    SecretVolumeSourceArgs,
)
from textwrap import dedent
from .util import snow_deployment
from .deage import deage
from pulumi_crds import certmanager


class Mosquitto:
    def __init__(self, namespace: str):
        self.namespace = namespace

        mosquitto_cert_secret_name = "mosquitto-cert"
        certmanager.v1.Certificate(
            "mosquitto-cert",
            spec=certmanager.v1.CertificateSpecArgs(
                issuer_ref=certmanager.v1.CertificateSpecIssuerRefArgs(
                    name="letsencrypt-prod",
                    group="cert-manager.io",
                    kind="ClusterIssuer",
                ),
                secret_name=mosquitto_cert_secret_name,
                dns_names=["mqtt.snow.jflei.com"],
                usages=["digital signature", "key encipherment"],
            ),
        )

        mqtts_port = 8883
        conf = dedent(
            f"""
            persistence true
            persistence_location /mosquitto/data/
            per_listener_settings true

            listener {mqtts_port}
            keyfile  /mosquitto/cert/tls.key
            certfile /mosquitto/cert/tls.crt
            allow_anonymous false
            protocol mqtt
            password_file /mosquitto/passwords/passwords
            """
        )
        config_map = ConfigMap(
            "mosquitto-config",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(namespace=namespace),
            immutable=True,
            data={
                "mosquitto.conf": conf,
            },
        )

        passwords = {
            "jfly": deage(
                """
                -----BEGIN AGE ENCRYPTED FILE-----
                YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSA5c2NDNEIxYmdXVTNuUTZL
                clI1eEozZXkySGVPM2Z1THZRa2FobE1EeXdNClRNejg2ZFdpS1hiaTlndmVUanB4
                UmFDaW8zUUUxeER5Q0xpNnpKMzl2bkUKLS0tIEFSZHYwcXlyMmtmRkpVSCtiQ0dU
                M09GcG0vaUxFRFJEeGdQRGJkOXRoWEkKoCgu0LmSeMeXdJUh1NYCvmxRvyBiGHi5
                4N0edEu3Bx08NGtOMCyIhIFbH04KLp0qE4sJP2Sbp7qDIGT9EluT2MwZifXjRrhk
                nj5806RLTQAE80Amq4S0ABHF0M0SnT4PK7ZwUWNegSZL9TZ4opgRTj3P3673kDFa
                MKJ1W2xRayxvQZf55TRXkaRXtaKldHA6
                -----END AGE ENCRYPTED FILE-----
                """
            ),
        }
        passwords_secret = Secret(
            "mosquitto-passwords",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(namespace=namespace),
            immutable=True,
            string_data={
                "passwords": "\n".join(
                    f"{username}:{hashed_pw}"
                    for username, hashed_pw in sorted(passwords.items())
                ),
            },
        )

        deployment = snow_deployment(
            name="mqtt",
            namespace=namespace,
            image="eclipse-mosquitto:2.0.18",
            pod_security_context=PodSecurityContextArgs(
                run_as_user=1883,  # https://github.com/eclipse/mosquitto/issues/3017
                run_as_group=1883,  # https://github.com/eclipse/mosquitto/issues/3017
                fs_group=1883,  # https://github.com/eclipse/mosquitto/issues/3017
            ),
            volume_mounts=[
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/mosquitto/data",
                    name="data",
                ),
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/mosquitto/config",
                    name="config",
                ),
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/mosquitto/passwords",
                    name="passwords",
                ),
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path="/mosquitto/cert",
                    name="cert",
                ),
            ],
            # TODO: look into k8s persistent volumes for this
            volumes=[
                kubernetes.core.v1.VolumeArgs(
                    host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                        path="/state/mosquitto-data",
                        type="",
                    ),
                    name="data",
                ),
                kubernetes.core.v1.VolumeArgs(
                    config_map=ConfigMapVolumeSourceArgs(
                        name=config_map.metadata.name,
                    ),
                    name="config",
                ),
                kubernetes.core.v1.VolumeArgs(
                    secret=SecretVolumeSourceArgs(
                        secret_name=passwords_secret.metadata.name,
                        default_mode=0o0700,  # https://github.com/eclipse/mosquitto/issues/3017
                    ),
                    name="passwords",
                ),
                kubernetes.core.v1.VolumeArgs(
                    secret=SecretVolumeSourceArgs(
                        secret_name=mosquitto_cert_secret_name,
                    ),
                    name="cert",
                ),
            ],
        )

        kubernetes.core.v1.Service(
            "mqtt",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(namespace=namespace),
            spec=kubernetes.core.v1.ServiceSpecArgs(
                type="LoadBalancer",
                selector=cast(
                    kubernetes.meta.v1.LabelSelectorArgs,
                    cast(
                        kubernetes.apps.v1.DeploymentSpecArgs, deployment.spec
                    ).selector,
                ).match_labels,
                ports=[
                    kubernetes.core.v1.ServicePortArgs(
                        name="mqtt",
                        port=mqtts_port,
                        protocol="TCP",
                        target_port=mqtts_port,
                    ),
                ],
            ),
        )
