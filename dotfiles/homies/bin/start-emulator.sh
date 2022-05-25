#!/usr/bin/env bash

trap '' INT
trap '' HUP

sudo systemctl stop kodi

DISPLAY=:0 sudo retroarch

sleep 2
sudo systemctl start kodi
