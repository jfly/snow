import pulumi_kubernetes as kubernetes
from typing import cast
from pulumi_kubernetes.core.v1 import (
    ConfigMap,
    ConfigMapVolumeSourceArgs,
    Secret,
    SecretVolumeSourceArgs,
)
from .snowauth import Snowauth, Access
from textwrap import dedent
from .util import snow_deployment
from .deage import deage

COLUSITA_CA_CERT = """\
-----BEGIN CERTIFICATE-----
MIIDmzCCAoOgAwIBAgIUN0rJPpEdbJi81Gx/sJCDcCZ8JjIwDQYJKoZIhvcNAQEL
BQAwXTERMA8GA1UEAwwIY29sdXNpdGExETAPBgNVBAoMCENvbHVzaXRhMQswCQYD
VQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5pYTETMBEGA1UEBwwKRWwgQ2Vycml0
bzAeFw0yNDAyMjkwODQ4NTVaFw0yNTA0MDQwODQ4NTVaMF0xETAPBgNVBAMMCGNv
bHVzaXRhMREwDwYDVQQKDAhDb2x1c2l0YTELMAkGA1UEBhMCVVMxEzARBgNVBAgM
CkNhbGlmb3JuaWExEzARBgNVBAcMCkVsIENlcnJpdG8wggEiMA0GCSqGSIb3DQEB
AQUAA4IBDwAwggEKAoIBAQCrfKXMUJmGfDdOZ93JnGDVg5aTpdUU6elDPOrt2T+R
h0l9vIpEAZ+e7NdzOLF5oLoFb6HUOFKimpYf/zmLCFb4NPY3GSuZdW3KdiX+27wL
wUOk5soF/Sf4oJA/ppoAhpaGWrfQs+6YlhPBlvMC9zAVXMC2TjqlrKGMLvI1hVy8
zqcroP8y10Do8Cw1rsqrCV1nYRqAu+Zf80epFcubwA73IWgH/j14i8YpnUM7YsWX
huHInI+Y//dfpDvyT1RFQol4R3QCL8GV47OyrYw9O/NOTHobjeKCcCd+77uJRS6Q
HqBrYMTNpCXgso36a//rXHKbkB7KT704ABzIGZpnY5w/AgMBAAGjUzBRMB0GA1Ud
DgQWBBSCMQKlcKi5AnmOWhLOw+cDG/NKNzAfBgNVHSMEGDAWgBSCMQKlcKi5AnmO
WhLOw+cDG/NKNzAPBgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQBC
yHvtSj2cuUlgCuu73aN7U7rjMojgSr5aeXWT9RVYajLTTp7PkC95jYAKssB4wn9k
7mKCBWebNil//dcJFRObQNAwtcWTEFrQqECZDTzZzzwCHhuMXtI85cnImHtJgQvN
iXRQt4AsHyEBgLUXuzzUr/IjFu+cEGEUReGMe21ZzzRbnSmK5IMbPd+EfWHWsWnu
jWyr75Vo2GU529cb6KNr8KQFSQ0eL4O26tRsbla+22BYqPpOOGtpgq0O62HwxWof
vM3fbE5EyHLLhJWRA1U029Q5K58hL1HQOT21VPWUxxU5vJ2P+SHPomRgVDAy3e1x
uLrtpKjJXezWZHulQfux
-----END CERTIFICATE-----
"""

# Generate key + cert for server:
#    ssh clark /mnt/media/ca/colusita-ca/gen-cert.sh mqtt.snow.jflei.com
MQTT_SERVER_KEY_AGED = """
-----BEGIN AGE ENCRYPTED FILE-----
YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBJUm4xdkVWeU5CMnpCUGMr
Q0hFdGhqZlNIL0RQc3RnZGQzQ1lDR2pieFJnCmxESFc0czExMUhXSmxGdWdlMGw1
aFRJRTFVTldHU0Jzd1l5L2pFTVEvc0kKLS0tIFh0LzNadTVuM1lhenhQeGx2Mk9V
SWhqQkpKNXBJc1gxZmhWbU00MGpzVEkKsLeLqtsBlFjBZlcz0pBeK9/KMVg6XG0z
Nb2RmXUXIZPuoHARJ35F+kfxWC+UrQTyDz/yupjCUJzEyN3Vt1x3aYodagpgK85O
8AMlXkOnR9jCrXoj/hBr3eBwnzzVC0jZO6G8swTBAX/TDi3NhYg042tI+GpfskLT
2hEDmZbQXYqtXLwepkNt9J0LK1lqlAOzW4+w8BciMypp7Rk5uhgM4wQm2S+ZcAya
sXUgAsoCZJWDmF3g4S9OgQu1vsiOonHdXOaxG4BdYJYCnBm+kjFgZpOAGhj+Vbyg
3IxiCX5NTDNhGjn3B64CxwtnqnJSLJ1QkftItEOz+2TohQBCrTSrmK79i58ynchX
+NbVnziV1kYZsVAVy2NFej8Wph7jj3jfFbba7ONmjquSjbKGltINdTka+J+3E/7e
u0mVKkxOP8qclw1o6+ousT8Ygx0qSu4MXqEw14HHeQIzTB4b2u2GXxGQaCLpOsFB
tW5FTWLpCwiZfm6/Zf2VXs8pQ6375V12k21Pmm0wBJK7XKpnJReJeC07O/+5lHVh
LpU8dCwZq9rtBLQAGdgFZ1Yv2fl94jTrBYmRKZQ3yeLNlZ+TCVn31og92Po/LAGp
DhVapHaejWSlA+R1TqblxZxgDNFTHunOxpRbSFDsN4UjQMtwqMP7aoRyAHZhDVET
PocSNDT/q4ndJt/oLhf51pVQ16J26DpoTJflPX10kVEYoOdmpyIRX/vAZu2lUS7/
D2mDZP0NLe1oHenLzlAL0HSm/kFGQusM3gzZ61/0/oqQfxNQIOGJtAnWMTNxEsTI
wsPPji+GND3FigXY8EH2knO7FAve3S375jSA+BTJrQjpow19VcL9Mp4ZMXHojoWB
q9I/PUO9vFMrFUCh23A2dhnBaHbWVXFKJBhm9zCrx0HC1fluqrRQsXaL2IZ3GAtN
AtNrG/UkfuCs9zpAT2/32uhRy16mdhC5TzAiPE2E1HV/+iHPsYcQM7nsH+hlKkMD
PZ9kDMlWtq6CBTLJ1vwXc3YziKmp1xP7tKOwWTT8N3CFaFZrfTs/hCoxHIUMGyuF
6Bnq58dmTKlOMJONrpAsk/8I/vq6im/WUofjBBOqD1UuPgIe/4XrQkZCeF5cnrst
RctQxq1l5CvlWW9jysQtn672OzhY3+MDuBQmeKFe39D04rNRXb/agwhoJKpL/Ptk
hz2gun2qAGVZ9woZiGQYb4+VLFKvTJs4JZ98FoDJSDiFa58HZ8DWsxiH+me1SCCk
uZ7HYaSbROZEeIjK01P7V0KzALcDYGLmsTYhGLx04++lD1Jc40Nz6PGXb99EGiQ0
PYfRNLDtyUrCI95OB2KFaUlwqZN2lS97+eJUSnW8iMM5a9Fszg/XVknPKSL0y9EZ
Nynmd3h88V08M1wQrjrTExHqufBCFQFMBQTx4zKFG+13MhMAdS86+YCt36bAV6tj
15I7E3D/rjGEKmfmWjhIiM+mrQzQVnqxp7f8iaKcpi5chkHJp0ulD+XM9c4c7uUU
UW3BI02FyVkrKL5ncZC65uBRx2yY+qkW4SXdISlHZwOAsgMtEVzIF0kTrpawNItT
cuBtKVSFWSg5nC9EcSW4+o0tdsV/lhn/2SBu9J3VQytrZ8BTQjq0wyqBj3ek0+dd
QjZH7J/J8gXYMAWktipR8nRxa1G7u17AN36HK+56XbNHYYh9xHru0CL6r/yzJHe4
/1Q51ZTaDwMBiRtw5Ea3vYwxU6bGobOYu8PJ3pbYxu2aW2PADVROJvNX+SiPH9fK
ps9mADuHvIwMjJpztCK86nMQhvbiloeVguyXi7pHp3QmZuKkB+FxWPlmudiKo7zK
EagSA1ZCe4rpCG2ccDKVLtvYKIXnDyE3b5U04Tu4rg+sIajSqeHpBiofMRrSsLO+
t/WqUOWgAqOb24NqTR4VoKIIdUWUWbJMQgA2f+mAkK1GYf1GrEH65idc12wDo//n
7Wx51f4btaO1ouuzgd/vjE/n+CUj1dx0yJ0kjv08cbt4DmaumGlAH9nw85PjAKrb
bDOwqgqClK9VHDRFCyK6QayMQHRb5WssvsAwQnW/3DXKRqUKI61AXPfoqrzcIY4o
oXN019FET78JPAA6/0k8VnlC+yGgMnVp70lHkBtOXQBPsRIS+D+PmbeWzxFaxtoW
QB9KkZwKmTyAc+x6tK6MYS3WPsVWZvTJDMFLayuWfaZiC/6dVoCiFJZCpJPmj7+6
jgslkZLXDPtYno50tkUKnhhF0XQy4PiBOf88UL3hBTe2IJEXaj0mpnegp3SxIwXh
Sk3c9Ao7HflQA7Nyp7fXFs6qgfZfV3YJAHI8t+rUU9I=
-----END AGE ENCRYPTED FILE-----
"""
MQTT_SERVER_CERT = """
-----BEGIN CERTIFICATE-----
MIIDYzCCAkugAwIBAgIUTqUsGezFXZhVNgRzR2b5n7J8HAwwDQYJKoZIhvcNAQEL
BQAwXTERMA8GA1UEAwwIY29sdXNpdGExETAPBgNVBAoMCENvbHVzaXRhMQswCQYD
VQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5pYTETMBEGA1UEBwwKRWwgQ2Vycml0
bzAeFw0yNDAyMjkxMTE2NDNaFw0yNTA0MDQxMTE2NDNaMB4xHDAaBgNVBAMME21x
dHQuc25vdy5qZmxlaS5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
AQC2mEEkZV+wzKFFeUQxwGQ0ubM05M7queg1R1WgK5fl5RXPspCz2gJGXUSMIZfW
71XI/fwCytJ3Nh2nrofjL2XdAqW8Vqid+HcWcziGUooRIjR8hKrFT6IBk7XYEQKL
+lwyrvSOwBLOT3c+cYZTx5fTUqNeJT58z5BJ0orkUwAJesZiaCljHzZ3dWOnHbII
LXXE59K2PqzAFBKF52NSNy+u2kVSaMQovR6TXJRDkk7Kqxiwn/MIFgrlA3AeF4Gq
lu5psRp0CW26aKG+x5qR4xvbf21oRvOPdLe9UgIWVJ248g8FvGticMVzXzZNe1zp
RLvzYIJ3CQVo+OiQN7ZLnihvAgMBAAGjWjBYMB8GA1UdIwQYMBaAFIIxAqVwqLkC
eY5aEs7D5wMb80o3MAkGA1UdEwQCMAAwCwYDVR0PBAQDAgTwMB0GA1UdDgQWBBTb
WZqJu4Xwzb2uVIH+dEYNmFJ2ODANBgkqhkiG9w0BAQsFAAOCAQEAOkZaz5LjDs5S
LZJcryEJpPWn+T2g3zXVMy3WgalaNIxx1kEoVd7tW7KTGmAGIiwfwe0flPgh2GSX
EsN25n2f2ZIQBr7QT+uQMDk4IeA62GkvmiHIlefgAL6SeyQmTE2VckHvPuw+BVB/
EOrXwcbSNf2JKo1+xQU3dQeO9jt58aiIIJLLFZ19T87moWz9kiA6xm4mVl2cgiKt
b8hfgWrTTLefUZG4Eaf5rwkL67kVMPmoFUkMuLp1l5kSk8LI8coq2sbdB7kCjLXL
MdLqKKsC9nfN6LvhY02ieOfyphkh75QCkb+TyD662e0ca2n7JSj9OM8RhNCrLTdh
kea40gmZDw==
-----END CERTIFICATE-----
"""


class Mosquitto:
    def __init__(self, namespace: str):
        self.namespace = namespace

        mqtts_port = 8883
        conf = dedent(
            f"""
            persistence true
            persistence_location /mosquitto/data/
            per_listener_settings true

            listener {mqtts_port}
            protocol mqtt
            require_certificate true
            use_identity_as_username true
            cafile   /mosquitto/config/colusita-ca.crt
            keyfile  /mosquitto/secret/mqtt.snow.jflei.com.key
            certfile /mosquitto/config/mqtt.snow.jflei.com.crt
            """
        )
        config_map = ConfigMap(
            "mosquitto-config",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(namespace=namespace),
            immutable=True,
            data={
                "mosquitto.conf": conf,
                "colusita-ca.crt": COLUSITA_CA_CERT,
                "mqtt.snow.jflei.com.crt": MQTT_SERVER_CERT,
            },
        )

        secret = Secret(
            "mosquitto-secret",
            metadata=kubernetes.meta.v1.ObjectMetaArgs(namespace=namespace),
            immutable=True,
            string_data={
                "mqtt.snow.jflei.com.key": deage(MQTT_SERVER_KEY_AGED),
            },
        )

        deployment = snow_deployment(
            name="mqtt",
            namespace=namespace,
            image="eclipse-mosquitto:2.0.18",
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
                    mount_path="/mosquitto/secret",
                    name="secret",
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
                    secret=SecretVolumeSourceArgs(secret_name=secret.metadata.name),
                    name="secret",
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
                ],
            ),
        )
