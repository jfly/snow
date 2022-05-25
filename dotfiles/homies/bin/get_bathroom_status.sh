#!/usr/bin/env bash

if [ "$(hostname)" != "dalinar" ]; then
    exit 0
fi

OCCUPIED=$(curl -s -m 0.1 http://g2g.honordev.com/api | jq ".occupied")

if [ "$OCCUPIED" = "true" ]; then
    echo -n "<fc=red>Not good to go</fc>"
elif [ "$OCCUPIED" = "false" ]; then
    echo -n "<fc=#006000>Good to go</fc>"
else
    echo -n "Could not connect to g2g"
fi
echo " | "
