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

# Some mqtt clients don't support mqtts :(
# See https://github.com/awilliams/wifi-presence/issues/21 for one example.
MQTT_PORT = 1883
MQTTS_PORT = 8883

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

        conf = dedent(
            f"""
            persistence true
            persistence_location /mosquitto/data/
            per_listener_settings true

            listener {MQTTS_PORT}
            keyfile  /mosquitto/cert/tls.key
            certfile /mosquitto/cert/tls.crt
            allow_anonymous false
            protocol mqtt
            password_file /mosquitto/passwords/passwords

            listener {MQTT_PORT}
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

        self.zigbee2mqtt_username = "zigbee2mqtt"
        self.zigbee2mqtt_password = deage(
            """
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBaQ1NqQjJzbk15OWF1dUx4
            c0ozYXNTeU1qcWlMTk1NR1UwL3AycVM0eTJrCldybytDaXRXQjVMN2RpZ1ZWeVl5
            OUZ3bncwVldwalYzUVRmV1QzK2E0RGcKLS0tIGFIY3NCQkVSQm9BZnk1UG4ycE9U
            d2EvZFN0TjlCa05rSVBtd1g3NFp6NmcKsL93AclzmnZYxLE39fdH7RUx6AEwbeT0
            3gaPZsEtQPDE29V0id1Di7FZkmkf6TSyNqxS1A==
            -----END AGE ENCRYPTED FILE-----
            """
        )
        zigbee2mqtt_hashed_password = deage(
            """
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBnVDQ0WUVJR21WSXhzd29I
            QzN4TTFxTzlFOFBlOHY5TW5DZHVieThseXowCmRQQnhYZ1NCc0RrVmRJaTl4Skx4
            M3VXOWhsdG42cEppQU9BVThYU3FsY0EKLS0tIFZGUkVxUkxVTHR4MFR0bUszOVBx
            L0twcStna042Z0hvMktYb3F4d2NIMTQK8hmIKxCv06Okp13FOKREIQVdJxQFvjiA
            MSMjg2Xzqza1rWu1YoIWH57bXQKmTpe6U77tFUVeuDiDqt2GUUJvEIgA+S+jSlLs
            YWBopm1G9pfWbZxS+IcGMiEgvbA8H/y86my/ycnY1hRE/uhlAKObd7eM3udPd0E0
            bHHdc8OQV2zmhBVDvEMzzxxMJfQL6n0VDQ==
            -----END AGE ENCRYPTED FILE-----
            """
        )

        # To generate a new mosquitto user + password:
        #
        #   python -m tools.gen_mosquitto_user cool-new-user
        #
        # And follow the instructions.
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
            "elfstone": deage(
                """
                -----BEGIN AGE ENCRYPTED FILE-----
                YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBsTXJhTFRCT0dldWYvdFBu
                anJjNEhvUmVjTVZOeVBuVjVRR0twY3ZaZ1NrCk8zSUxLTzNDdnU4R2N6ZFdKNkd1
                citlTTJHTVkzb29DRUJJRXVqdHBvT00KLS0tIGNlVHNkUlUwMDFPVGZ2cFFyM0hN
                ZUxsQW4rRWdOQ2JpUllYUDJrS1gwY3MKfrwTiGFVvq5YR3NqwOH8yHf2TGYGIVxw
                4jIoBW+SbTYWEgptmSqBKBlIEN5VIZVZgk1AE/BTSu2UlhISVqgfibbXtsobLW0n
                N3zTLwlsUgwMixu6vgQPz8H/LBwf89QOEBDKCDEg7sA4+xFk/eo9wBv04xsWcCZ7
                ztgtczsinA2nNbvVSrhoyO47h9fL8dZF
                -----END AGE ENCRYPTED FILE-----
                """
            ),
            "pelydryn-dining-north": deage(
                """
                -----BEGIN AGE ENCRYPTED FILE-----
                YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBUaEcxeFlZMHI4akxFRVJL
                TGhiT0x6akVWcDZuRkszSk9WZ1dEQVlqTVdBCjFlSEpBYnFnZUpWd3VyWnhDRWtk
                WG5NaFJHZGhvUlVacldISDBmM1FmS28KLS0tIFBsSWJTdms2R29mbG1sYmEzcmFr
                S1puT3gwdU1oOVNjaEhXZy82TGxaZWMKswZ3IHbQALBMTX4YE5cIlnmKQeNY5cWa
                djXY+v4V6LouEoQYqmPRhk/ubP78M2hETvyQ9QOieYGw4SDZVX6Ym9RBJEBlLv8S
                7fpEGJs3zusvPFpy2TXJr5nGMO4QDeCDvOLfX7MVL8zCJ6Rld7yG7+xbyKeBgmYQ
                pjvAu7NCsfPMdPrcnDZuiOfFV+Ye8oVb
                -----END AGE ENCRYPTED FILE-----
                """
            ),
            "pelydryn-dining-south": deage(
                """
                -----BEGIN AGE ENCRYPTED FILE-----
                YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBrWWpwbVA1aU9jbkY4WVYw
                ajhYK2pIdDFjVVFCK2c2b2xLd3loR3dWazFZClhsWTRxNXgrTi9wUkRCT0R2Zncx
                cmtEMmhaWGR6NnFFTUZQdHlHOGh2WFUKLS0tIEcyZU9mVGJrQkw5eCt4Qk5VSktk
                QVB2YmkzaFVRbmlPZzgxd2ZOMTlsakEKkmnMybAR4L0gLetyJDta2TAMal/YYXt8
                IFJuJk7MVmK3+enKUaHJ1Sc1rH/OvDhQy4dpyIaobEKhc/DsXE99fvT2B93vuVF+
                JTeg36hXYPXesExzUYge8V1NS1uMdx0EuaEk1//tQ/lg/sA/LwTMsj3QNSRc0AVg
                tRoHDXBzGLj6UAVag63XP2bLlIqKXxXR
                -----END AGE ENCRYPTED FILE-----
                """
            ),
            "pelydryn-northeast-bedroom": deage(
                """
                -----BEGIN AGE ENCRYPTED FILE-----
                YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBnS01jYTNkNmZzYXZ6ZFJx
                ZzRMRHl2TXMxYmJ2NDJqR0VYMEh1c2JoQ2hZClJoaGkySzh3Z0lxZFpCN202bURa
                UTB0cTBXZXhMTEcwbzFSM1B6UUhwMkUKLS0tIEN4aWZENG5aRmhUS3NRZVNHRm9a
                dFp0eThpMFlIWUNVWXJEdU1VVTlqRGcKWgGQS7d2S54Yd2VVQEsDT46uZjputIrO
                rBd5KCym/ABFazYZ9hfNgiL3NBTnHskeyffMO1lfN2aOSTd+HZ4inbYPRA5VhsEH
                P0aEkQsPitU8+DNKReIkaRHNdzC/gGeg2nOguV98amjKvXNv9RhPeHf+34cavHBH
                hafxC5p8JBGS1+94c0X9NRSO2CZYMzbiZA==
                -----END AGE ENCRYPTED FILE-----
                """
            ),
            "pelydryn-northwest-bedroom": deage(
                """
                -----BEGIN AGE ENCRYPTED FILE-----
                YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBtNmhqNTUya3NsTnFPV084
                aUY2bno0ZmVkelRPMW43QXBlVG1wZXpsSDE0ClBZL3RDQ1M4VWJOZnE2ajZsN1Ja
                c0M5U2piRWNZNlA3TlQwOVR3dzZhanMKLS0tIG1LcVNwMXNkZDdEUkJ3Sk1EVUwx
                VlI3RWhVN1BsM0dkV2libk14WEU1VVEKuM49g5JpYyQ44YMjyv0pe8/0Ft9YHoGM
                eL/fJ+xcEQXSR89wPjWBCDWvtsIt4T0ZAUHfSO9101nLT3TSJKbnd1hHSIvKVnWq
                6vLeyxLrOKo5YAyYh6eAXmjbzL1PdkL6CIF3EFhyB7qFquNsBRzqBYZh7r6bUEjD
                6vBF/DIvitiQ70I4bDrsv9ZKax3AY6S5CQ==
                -----END AGE ENCRYPTED FILE-----
                """
            ),
            "pelydryn-north-bathroom": deage(
                """
                -----BEGIN AGE ENCRYPTED FILE-----
                YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSB0Ui9JellPK0l5eTVsZHh1
                eXhPNUhiblVjWlc5ekU2L0QvRGd2RGdyeTE0CkxzQUpqcWhHQmlIZVNOMlUxN3B2
                N3Q0dmFRdjlaUVFFUjg2d292YjZOYncKLS0tIEk2L2o2R3g2bXgwSDNNbTJPTHBB
                TjVZYWpGRGZ6eEdncE5qRHFuVUtEcW8K2VL29SlGsve6fE2AqbISlx3m4C0Ood65
                K7XRg9fJ5+08F9xdrJA3VSj2oCImRmrQWozGoBZh02IqXWGDeNKxMqIWUXjrOsn9
                4bKDZGo6OmPXoWOEgDXQvZ4dQ+C4qlfgK24xwPgTuvQ05muY22i39RqVoIXtFOt/
                3FfloAWRmJfJp8DtGkpPcCuGl65xgKuurg==
                -----END AGE ENCRYPTED FILE-----
                """
            ),
            "pelydryn-kitchen-north": deage(
                """
                -----BEGIN AGE ENCRYPTED FILE-----
                YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBNYUVTOVRwSS9JaTg0MDdp
                TC9WZTRWOG9zcnZJSXE4bjNHT2JCcEs2d2dBCmk5NkdhWEpsZTB3OUFyUWFweFh3
                ZzJRaXlXeTMwMTliRU5zZVVxOUUweU0KLS0tIFpCdDFiMzVxa2s5U0w1YkpaUGJs
                Z285VU5tQXFWN0VjaHdCMHNXRFJZamcKklDsYupt/5Kty3plbJq+hhlIYQTG6Skk
                1RWgGK4tz14lo8LYqwy00owAgruyCxObe/mgStyaMjtMztZGQxp22nr9T/F4haAZ
                bu2p7QVIpkPleZhT0z6A3mLOdCS80QK6Le4Fiq9b7rRk1wqBGsnH8+JB8kf+qLk2
                d8xyHOYY42Tv48rJ3u4lkYTAWWIAIyXbjg==
                -----END AGE ENCRYPTED FILE-----
                """
            ),
            "pelydryn-kitchen-south": deage(
                """
                -----BEGIN AGE ENCRYPTED FILE-----
                YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBGbG9KM1gxVjBFS0ozbm9P
                aldZWWR3bUF1amthdlJWRnlmdVNseEZudWdNClFLNGZod09UMjhlanQvTHdBODUr
                OFEzU2lJQkoyUlR1bDlCOVRJa1JDWm8KLS0tIHNZN0h3M1c2bmc4bU1hcElwRHJT
                RU5xeGEwSXBBanJrZWlwd0g3RWV2UWsKacO7nsZulaX+SyfDSeRlUdiqysYlBjl8
                X+WI1utTT+tib0WASUe6N/YbS7shIlS1Y/ekMUFVr3uMnpMf3mqkLV3i0LGk0aUa
                FiWQmIyHamsttQQ89f62RUaMKvrv6OJT3bCqPdAjW+16ZcwQApmIxi3+csE/fd7L
                qPR567H1i9dSoCr+MMN/magrjtfAE6z61g==
                -----END AGE ENCRYPTED FILE-----
                """
            ),
            "pelydryn-living-room-east": deage(
                """
                -----BEGIN AGE ENCRYPTED FILE-----
                YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBvZW44aWFubzk3aXR0SVVN
                c2dlQWlTOTVTMDlzUWVrdWF6Zk5XaGNISjFRClNEaDNoZHZBcStma0pLVUJFaU8y
                UkRINHdjTXZUSTFIMjQ5TFlwUTFFeTQKLS0tIC9tSCsxeFp0cm4yLzhFN0dJYlEr
                aGhzTVdCMlZhVkFxbUVJWmEyUGdaMm8KPKvhuUHJu3G2vhecl+Xkw+g0nE4ozqw4
                zmZ9KVuJw369SAI9qBdvFAcPlVVRngmJ0Gt+yg8mYEI/9lBiPz6iBDMD4EDSk95h
                vQ6Hookb42BNS6F3WMOhYRRR99poX7dy2O5jS2GhmjBUPdDLaFJu6fAA8+dQcSQB
                9d9ytLdsQOPZ4gpULu7dYvpwOxoRnJ5IOw==
                -----END AGE ENCRYPTED FILE-----
                """
            ),
            "pelydryn-living-room-south": deage(
                """
                -----BEGIN AGE ENCRYPTED FILE-----
                YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBSRUhkNzNBSGRtUmcwUjdy
                Mm9PbG5QSldWU3FYMWl4c2N5RFVXTGRvSDI0CjNacjZMbVZxY1hkNWQ5RkdGcEQz
                NnJFUW0xK1ZnSFBsN3RGZTl6QnlucTgKLS0tIGNKaGlDU1FOOXVXYW1ETjBYZkpS
                SWNMeC8rb0R4RkM4bWZLVmZBQy9uZ1EKABjW8iiSQk9nbibrrt7+AdDa4ObkJtWm
                s0UVXdLLfL1wqM/Umt6aqu07gc7cFEIeCtxgWtB0zvTNKZk0airO49LO5YR1PsPO
                Fxz0ipaoy9AlPbH9dyRfmbnHeFjdaI0GNyCI0Os20YVshL9iKHoRMgrBZRk5MV7L
                uZnqk0PMPgih2QESBEXlQmyVqObqiR0FJQ==
                -----END AGE ENCRYPTED FILE-----
                """
            ),
            "pelydryn-fireplace": deage(
                """
                -----BEGIN AGE ENCRYPTED FILE-----
                YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBTdS92ZWQ1cW1Ta1l1bDJs
                c3dUY29Ycy85UXowc24vQmF1S3MyY0J4LzNZCmVxWXhyc2Z1R0VwTE9YaFRtbmp5
                eWNWc0h2OFhiMm9RcE1RM082SFBxZkUKLS0tIFFieU9mWjZlRUdORzNmMFNieE9o
                V2xMMWVVMUlXU0UwajNlVm90cDhLMjAKKtr/NEuPYIhhKeF4yoFoN0zZfP/cb1+q
                UO61GMgEDjW73Fg6SkrtQcQbhxD/tghey1AJMuMBU9EDvOknRMVz3V2GJJ9egS/b
                4OPw/pnjAI4WKKjC8RuQPD8qeLUnbBYJNoUd0PMZwqtm58kurhkJFUnNwNpoWuAO
                addN+NSTzFwgfQnHpKvQsU9JgV8vT6lu5Q==
                -----END AGE ENCRYPTED FILE-----
                """
            ),
            "pelydryn-south-bedroom-north": deage(
                """
                -----BEGIN AGE ENCRYPTED FILE-----
                YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBNQXA3bTJYajN3ejFwSk83
                RUdqNCtLUDAwczM4dWN5YkNTeXpmYXdTYXdZCnlBSVEvZi82UnhrMFpRMkxrcHN2
                M1lMTlF3aFllQzN6Uk9CQVVkc0dFcFkKLS0tIFBFYURackZ2aW1hNzFYUmh6bVRs
                aC8rbWdDdFBDNXRxYndINUZmQVJrSmsKMFyGbODl8TUb+58K9njLUgLBQ5Iqrn12
                2VS0l1rYIhxCuCQTb6S3WXHeNn5/++w070f7nGah/D30fkeBntCIFJm3dd0bEYW1
                DxrjmG1eKf+4YZ7OVWTsoL2rZPyebwpoGbtyShjXKkOt8y54pnxctZQu1sFl6DCt
                uDgJ0jHIH5E0PCPbKzS0bLYrA1YJAazZJw==
                -----END AGE ENCRYPTED FILE-----
                """
            ),
            "pelydryn-south-bedroom-south": deage(
                """
                -----BEGIN AGE ENCRYPTED FILE-----
                YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBzT3dJWS95Sk5lNldXejFV
                RHlTVzMvMzZLa3U0cjlQTi9ROU5yOTFmMjBBClRQVlVCdDFkVmczdW4zMmNUYnIy
                SkovRG80UnhXR1V4NWhmQmh1aVQvMlkKLS0tIFhLQkhDSHlNUGVjbURmWGpVQ2Y5
                Q1BsYUNmdHJaQ3lWRmxuMnRMTFlDTGsKi3FE4yykxgRIIEOo21ag9G9691Cq/MqW
                cTlJ1zgoU6oZkubeUGo5TqOo0Kg285G7TAbCdWHPVKFJHB1m881s1PaWnkj6s4vK
                ELgpejwZl0n+h8eKsFCQ586SO8cS9JToRh4T9GLj0I+RXfoULdygt39MQL+up/44
                bQiNn7gyibz+BLCbVIZIHNY/jXiuI87y3A==
                -----END AGE ENCRYPTED FILE-----
                """
            ),
            "pelydryn-south-bathroom": deage(
                """
                -----BEGIN AGE ENCRYPTED FILE-----
                YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBxMUpIaGpnNzZFN09aRk9U
                YnFhVzlFSm5BaFcvaHRxbUVjTno4R0xWbUZ3ClpnYzFYVVUyelFmNlVRbzVVNTJm
                R0xlZlNQQVF4cWQxUEdzSGluUkdWdG8KLS0tIGoxcWhZYXhLZFNYYmFZZEkxQU5V
                T3hZb3BBTjhIUCt0cEEzeEdKMWNtSjQKOFdG0DLBZ8kNF7IQR+EdELrG2X3iUmvD
                vfMrvTOlFHq8pe7b+0YXGlgSMrMF9TNNfB95Ow3qwKw4sMU2lZMmyJyDAeDCaIjO
                Ym+a7cBWCFYy1e53KeTFVs2K82m1cxNapARmMwIZeEqZN0u4jFY9Ya90cMLhJLd2
                iTaTb9+9IaaqQ3JeFXjqtc6FivUkAEcjvA==
                -----END AGE ENCRYPTED FILE-----
                """
            ),
            pulumi_username: pulumi_hashed_password,
            self.zigbee2mqtt_username: zigbee2mqtt_hashed_password,
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
                        port=MQTTS_PORT,
                        protocol="TCP",
                        target_port=MQTTS_PORT,
                    ),
                    kubernetes.core.v1.ServicePortArgs(
                        name="mqtt",
                        port=MQTT_PORT,
                        protocol="TCP",
                        target_port=MQTT_PORT,
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

    @property
    def hostname(self) -> str:
        return "mqtt.snow.jflei.com"

    def url(self, mqtts: bool = True) -> str:
        if mqtts:
            scheme = "mqtts"
            port = MQTTS_PORT
        else:
            scheme = "mqtt"
            port = MQTT_PORT

        return f"{scheme}://{self.hostname}:{port}"
