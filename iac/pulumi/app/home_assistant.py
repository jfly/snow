from .resources.mqtt import MqttRetainedMessage
from .mosquitto import Mosquitto
from .deage import deage
import json


class HomeAssistant:
    def __init__(self, namespace: str, mosquitto: Mosquitto):
        self.namespace = namespace

        MqttRetainedMessage(
            name="wifi-presence-config",
            topic="wifi-presence/config",
            message=json.dumps(
                {
                    "devices": [
                        {
                            "name": "jflysopixel3",
                            "mac": deage(
                                """
                                -----BEGIN AGE ENCRYPTED FILE-----
                                YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSA0enN3TTdxL2ZCM2R0MXph
                                M25mVGZqMGJNNzJBNTNreG5YM08rZWtON2s4CjEyRHdWZUdiNkVYMG85THBRWHdy
                                UlQ5UG9XUlFSejFCbk5od1QxVjY0b28KLS0tIGNzOEp6c05vRzYrUVR4Q0xzMVcx
                                ZjJyMHR2MjYxUU5ZeDhRQXRpOVg2M2MKLdPGPMOOqW0E0HfgvfznALLli8Ai7F26
                                OmPr5h/Ilq/19rlCBbBqZ0J346Egypicog==
                                -----END AGE ENCRYPTED FILE-----
                                """
                            ),
                        },
                        {
                            "name": "RachelsiPhone2",
                            "mac": deage(
                                """
                                -----BEGIN AGE ENCRYPTED FILE-----
                                YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBraWFlbjBSR3VvMkxkbmZT
                                R2lIT0RITjNzZHhHQncyUmNLN0hPTWV4NWtvCmFXenRsZ3VxcXQya3R0Njg3K0Vz
                                WVMwZXVKYmR5Q2l6UjZpU2hwZGtHcWMKLS0tIG5ESUt3bDlCMU5TTnljcytuVXNY
                                UllnaUdhRXl6cFBUb3V2WmFPZXI1QzAK8wLdiaKqLsWaIZGhORcsNzyQeaZD4b2P
                                bBGWm7Rn3/Vl3NN3H9m+IimMwYMD8tkdtg==
                                -----END AGE ENCRYPTED FILE-----
                                """
                            ),
                        },
                    ],
                }
            ),
            provider=mosquitto.retained_message_provider,
        )
