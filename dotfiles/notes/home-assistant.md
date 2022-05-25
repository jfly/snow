## change password

    ssh clark
    docker exec -it home-assistant bash
    hass --script auth --config /config change_password USERNAME PASSWORD

----------------------------------
https://www.home-assistant.io/docs/configuration/secrets/

Getting this error on startup, but I can't figure out why:

home-assistant   | 2020-03-07 09:38:45 ERROR (MainThread) [homeassistant.core] Error doing job: Task exception was never retrieved
home-assistant   | Traceback (most recent call last):
home-assistant   |   File "/usr/src/homeassistant/homeassistant/helpers/entity_platform.py", line 425, in _async_add_entity
home-assistant   |     raise HomeAssistantError(msg)
home-assistant   | homeassistant.exceptions.HomeAssistantError: Entity id already exists: person.jeremy. Platform person does not generate unique IDs

maybe some conflict between the first user i created and the person i'm defining in yaml?


# Getting a sqlite exception when i try to place the config folder on /mnt/media. it works over at /home/clark/tmp/ha-config/, though!
