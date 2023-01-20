FROM homeassistant/home-assistant:2023.1.6

# Upgrade to the latest version of zha-quirks to pull in
# https://github.com/zigpy/zha-device-handlers/pull/2105/
# I'm not sure why I need to uninstall zha-quirks to get this upgrade to occur,
# but I don't really care, since I'll hopefully get to delete all this once a
# version of home-assistant's docker image comes out with a new enough version
# of zha-quirks.
RUN pip uninstall -y zha-quirks && pip install -U 'zha-quirks @ git+https://github.com/zigpy/zha-device-handlers@a16c153131afffdcdcae711e1695575d8267d703'
