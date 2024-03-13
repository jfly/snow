from .resources.mqtt import MqttRetainedMessageProvider
from .resources.mqtt import PasswordAuth
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

        # Some mqtt clients don't support mqtts :(
        # See https://github.com/awilliams/wifi-presence/issues/21 for one example.
        mqtt_port = 1883
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

            listener {mqtt_port}
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

        pulumi_username = "pulumi"
        pulumi_password = deage(
            """
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBScWc0MWs3UzU0NlpvYmJq
            TnA3ZUo3WVlzU1VuNGwrYTFVVkdKNndzaEVBCm1YbFZaYm45U28yV1lsVy9PR0dw
            bkljZVBDSHdqSjZwWmNWR1VLT01oc0EKLS0tIHpBRGxyUHJoaXp3eGltT0lHamgr
            WnEwWTEvdW9GanlCNDBoNFJvQis3M2cKGYSqFxtL2ZPS8tNOE8en276fVPMZh2Nn
            BpKP+TBBhfISgBQiyhkPEM2BO6g2bqJyrN5yxw==
            -----END AGE ENCRYPTED FILE-----
            """
        )
        pulumi_hashed_password = deage(
            """
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSB2YmFJaVJ0ZzFCaTdQWS9Z
            ODFnSGFHTHh5OExrbHpzb1hnbXd2aFNGU3djCmhNaGNMdXE5OE1SWld2TnlqWmxV
            N0RLNEtsNFdWQTVuNy9wZUxSVmtVYXMKLS0tIGFIS2pRZUFhTXAzVXlza09YR2dM
            aUlVZlV3eHpZUW5DSmRlTDJYRjJUVzgK/txylOKH+1d5QuiFIZU+ndhcPp3kuckP
            l1Ad79TOqeqvIDPHtGxwXsgPfMAsOOuUq7xxQPIhkU1jaoFe1exA/tEFG/5Go6On
            k0qZc1p1WOP4DeBYAStUNuEm02c2bOTovEsDirVRt0F51FaPTHlPyYAKzDX0S9+m
            ZAu4GpuPStgU64UKn6q2ZgtYM1gfh5CI
            -----END AGE ENCRYPTED FILE-----
            """
        )
        hashed_passwords = {
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
            "home-assistant": deage(
                """
                -----BEGIN AGE ENCRYPTED FILE-----
                YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBSTWx5aThtZERwTVEyaUZL
                ZU1heGVPT1YrNGZzNTNyc0EvMWM3ZWgvNVdFCmNDWlA4NmErV1RWQWdJQ1BiV0or
                OGdkU2NhWWU3RXpsWjFZektwb0QzSzAKLS0tIDNOMDhCdVZZcytMWGNsa0laVldl
                UVFrdVYvZExOTkxNZi9PWk41L3N6dzQKC6rz10ypryyM7ZBN9gsfC4DSu2WaR3O9
                xUiK/o4Bl9h4zt41DeviJdxZgoPjTV3faoDINeUUSWcdwFHKxkKiAYQbNmm10G5K
                DfauH8Qy24RdZiorEqS+DL1KpveIdDigzFQ3zajFLr+2ELb7y+3P1FPw8ULD45wG
                KbCc32h0LkL+1n0ixDqXM8x2+beo6B/U
                -----END AGE ENCRYPTED FILE-----
                """
            ),
            "strider": deage(
                """
                -----BEGIN AGE ENCRYPTED FILE-----
                YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBlRzlBYkszdTEzVU9DbkNL
                UG5pYS9vYUtOTVd0RDhvUFRLSXpUaWZsajIwClhsN2s5ZTB6QTR6Y2JnZ3Axem1I
                dVFIcE5kSEJlKzVkZ1U0NGtRQWFDdVkKLS0tIENQV0FWbXpBL0tGRnpDdlJNbXF3
                dEhGK2kxL3RnUkxPUTk2WmdlSHpNalEKml0PGsgAvTCoO9O41PyWwz0a3kUVJvCC
                e4w9WXwbDOVtNqORoDEeqAIJNXNCKe/8AmHIKXqcHClWpwGq3qScvebxihqq9NcJ
                0V6ltaP/lOKbP1rnGFXVVpSSHN9JiKrO6anp/4xav6dUQHn3Z0RkYwF95weLwrMd
                HL8ujuXg5dNQy8k040lp+GdmVboFY4x2
                -----END AGE ENCRYPTED FILE-----
                """
            ),
            "aragorn": deage(
                """
                -----BEGIN AGE ENCRYPTED FILE-----
                YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSAwN25RN0dPOWNJT1ZVNnpj
                ZCtENHdIMHZkQm51TVFCcVlwMFpreUcvdVdVClVxTjI3L3d2VEVxdkRtNEFXbXJr
                cGFOREJ4Vm1EZmthaFk3TWpPTlFjLzQKLS0tIEdaWEt5a205S1J1MTNTYjZLVlpQ
                a2dMRFpyZ1l5MFM3dlVlU3Fzc2w1RlkKVot31vpoBanDnSlY+UeQgGDeSlBT+MX6
                3tON/nBa4lt5dNAmQL7F64r7qT8OQcSZVPdyD9WsoJQkEExaBOmhtRzHUsGRf883
                A7DrhksL+VnX5utrg130ZtvirBwiRvT1MLTtveWVmNuMgAFOTJcCiIn15mSRHFTr
                YcIwOx3Vgb0wuWjf97Q4NOGqy8lkdFld
                -----END AGE ENCRYPTED FILE-----
                """
            ),
            pulumi_username: pulumi_hashed_password,
        }
        passwords_secret = Secret(
            "mosquitto-passwords",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(namespace=namespace),
            immutable=True,
            string_data={
                "passwords": "\n".join(
                    f"{username}:{hashed_pw}"
                    for username, hashed_pw in sorted(hashed_passwords.items())
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
                        name="mqtts",
                        port=mqtts_port,
                        protocol="TCP",
                        target_port=mqtts_port,
                    ),
                    kubernetes.core.v1.ServicePortArgs(
                        name="mqtt",
                        port=mqtt_port,
                        protocol="TCP",
                        target_port=mqtt_port,
                    ),
                ],
            ),
        )

        self.retained_message_provider = MqttRetainedMessageProvider(
            hostname="mqtt.snow.jflei.com",
            password_auth=PasswordAuth(
                username=pulumi_username,
                password=pulumi_password,
            ),
            # The deployment needs to finish before there's an actual mosquitto
            # instance to talk to.
            depends_on=[deployment],
        )
