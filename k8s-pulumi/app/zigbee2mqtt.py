from .snowauth import Snowauth, Access
from .mosquitto import Mosquitto
import pulumi_kubernetes as kubernetes


class Zigbee2Mqtt:
    def __init__(self, namespace: str, snowauth: Snowauth, mosquitto: Mosquitto):
        self._namespace = namespace

        host_serial_path = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_4e9906adc812ec118b8a23c7bd930c07-if00-port0"
        containerized_serial_path = "/dev/ttyACM0"

        mqtt_username = mosquitto.zigbee2mqtt_username
        mqtt_password = mosquitto.zigbee2mqtt_password

        snowauth.declare_app(
            name="zigbee2mqtt",
            namespace=self._namespace,
            image="koenkk/zigbee2mqtt:1.39.1",
            port=8080,
            access=Access.LAN_ONLY,
            env={
                "TZ": "America/Los_Angeles",
                # https://www.zigbee2mqtt.io/guide/configuration/
                "ZIGBEE2MQTT_CONFIG_HOMEASSISTANT": "true",
                "ZIGBEE2MQTT_CONFIG_PERMIT_JOIN": "false",
                "ZIGBEE2MQTT_CONFIG_MQTT_BASE_TOPIC": "zigbee2mqtt",
                "ZIGBEE2MQTT_CONFIG_MQTT_SERVER": mosquitto.url(),
                "ZIGBEE2MQTT_CONFIG_MQTT_USER": mqtt_username,
                "ZIGBEE2MQTT_CONFIG_MQTT_PASSWORD": mqtt_password,
                "ZIGBEE2MQTT_CONFIG_SERIAL_PORT": containerized_serial_path,
                # https://www.zigbee2mqtt.io/guide/adapters/zstack.html
                "ZIGBEE2MQTT_CONFIG_SERIAL_ADAPTER": "zstack",
            },
            container_security_context=kubernetes.core.v1.SecurityContextArgs(
                # I haven't found a better way to give permission to use the character device.
                # See https://www.reddit.com/r/kubernetes/comments/13j791x/zigbee2mqtt_container_with_usb_device_but_not/
                privileged=True,
            ),
            volume_mounts=[
                kubernetes.core.v1.VolumeMountArgs(
                    name="data",
                    mount_path="/app/data",
                ),
                kubernetes.core.v1.VolumeMountArgs(
                    mount_path=containerized_serial_path,
                    name="ttyacm",
                ),
            ],
            volumes=[
                kubernetes.core.v1.VolumeArgs(
                    host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                        path=host_serial_path,
                        type="CharDevice",
                    ),
                    name="ttyacm",
                ),
                # TODO: look into k8s persistent volumes for this
                kubernetes.core.v1.VolumeArgs(
                    host_path=kubernetes.core.v1.HostPathVolumeSourceArgs(
                        path="/state/zigbee2mqtt-data",
                        type="",
                    ),
                    name="data",
                ),
            ],
        )
