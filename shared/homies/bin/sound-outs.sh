#!/usr/bin/env bash

# First restart pulseaudio to clear up any devices we may have left behind.
# TODO: instead search for any devices we created and unload only them?
# TODO: restarting doesn't work, it seems to cause any bluetooth devices to temporarily disappear.
# pulseaudio -k

# Prompt user to pick outputs to join.
SLAVES=$(pactl list short sinks | fzf -m | awk '{ print $2 }' | paste -sd "," -)

if [ -z "$SLAVES" ]; then
    echo "You must select at least one sink to create a combined sink"
    exit 1
fi

pacmd load-module module-combine-sink sink_name=combined sink_properties=device.description=CombinedSink "slaves=$SLAVES"
