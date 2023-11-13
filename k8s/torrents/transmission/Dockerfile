FROM ubuntu:22.04

# Install + configure transmission
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y transmission-daemon
COPY config/transmission-daemon/settings.json /root/.config/transmission-daemon/settings.json

# Install + configure pirate-get
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-pip
RUN pip3 install pirate-get
COPY config/pirate-get /root/.config/pirate-get

# Create a media group with a specific id.
# This is similar to the PGID/PUID stuff that the linuxserver folks do:
# https://github.com/linuxserver/docker-baseimage-alpine/blob/880fac8727d29232d50c17e52ce4dc3da5ec32b0/root/etc/cont-init.d/10-adduser#L6-L7
# TODO: DRY this number up with all the other places it shows up in our infra.
RUN groupadd -g 1002 media
# Change the primary group for the root user to "media".
RUN usermod -g media root

ENTRYPOINT ["transmission-daemon", "--foreground", "--log-info"]
