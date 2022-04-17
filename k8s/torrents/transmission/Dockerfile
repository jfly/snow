FROM ubuntu:20.04

# Install + configure transmission
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y transmission-daemon
COPY config/transmission-daemon/settings.json /root/.config/transmission-daemon/settings.json

# Install + configure pirate-get
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-pip
RUN pip3 install pirate-get
COPY config/pirate-get /root/.config/pirate-get

ENTRYPOINT ["transmission-daemon", "--foreground", "--log-info"]
