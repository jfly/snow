import time
import pulumi
from pulumi import Input
from pulumi import ResourceOptions
from pulumi.dynamic import Resource, ResourceProvider, CreateResult, UpdateResult
import paho.mqtt.publish as publish
from paho.mqtt import MQTTException
import datetime as dt
import logging

from dataclasses import dataclass

logger = logging.getLogger(__name__)


@dataclass
class PasswordAuth:
    username: str
    password: str


class MqttRetainedMessageProvider(ResourceProvider):
    def __init__(
        self,
        hostname: str,
        password_auth: PasswordAuth,
        depends_on: list[pulumi.Resource],
    ):
        self._hostname = hostname
        self._password_auth = password_auth
        self._depends_on = depends_on

    def _publish(self, topic: str, message: str, timeout=dt.timedelta(minutes=1)):
        start = time.time()

        while True:
            elapsed_seconds = time.time() - start
            if elapsed_seconds > timeout.total_seconds():
                assert (
                    False
                ), f"Timed out after {elapsed_seconds}s trying to created MqttRetainedMessage"
            try:
                publish.single(
                    topic,
                    payload=message,
                    retain=True,
                    hostname=self._hostname,
                    auth={
                        "username": self._password_auth.username,
                        "password": self._password_auth.password,
                    },
                )
            except MQTTException:
                logger.exception("Error connecting to MQTT broker")
                time.sleep(1)
            else:
                # We successfully published the message! Break out.
                return

    def create(self, props):
        topic = props["topic"]
        self._publish(topic, props["message"])
        return CreateResult(topic, {**props})

    def update(self, _id, _olds, props):
        topic = props["topic"]
        self._publish(topic, props["message"])
        return UpdateResult({**props})

    def delete(self, _id, props):
        topic = props["topic"]
        # To clear a retained message, clobber it with an empty retained message.
        # https://thingsboard.io/docs/mqtt-broker/user-guide/retained-messages/#deleting-retained-message
        self._publish(topic, "")

    def __getstate__(self):
        state = self.__dict__.copy()
        # Remove `self._depends_on`, it's unpicklable, and we don't want it sent anyways
        # (it's only useful for setting up resource dependencies as below in MqttRetainedMessage)
        del state["_depends_on"]
        return state

    def __setstate__(self, state):
        # Restore instance attributes.
        self.__dict__.update(state)
        # See comment in `__getstate__` explaining why it's ok to not hydrate `_depends_on`.


class MqttRetainedMessage(Resource):
    def __init__(
        self,
        name,
        topic: Input[str],
        message: Input[str],
        provider: MqttRetainedMessageProvider,
    ):
        full_args = {
            "topic": topic,
            "message": message,
        }
        super().__init__(
            provider,
            name,
            full_args,
            opts=ResourceOptions(depends_on=provider._depends_on),
        )
