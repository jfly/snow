#!/usr/bin/env bash

IMG_DIR=$(dirname "$0")/img

# This is the best way to check if your microphone is muted.
if pacmd list-sources | grep " *\*\|muted" | grep -A 1 index | tail -1 | grep yes > /dev/null; then
    volnoti-show -s "$IMG_DIR/display-mic-muted.svg" -m
else
    volnoti-show -s "$IMG_DIR/display-mic-not-muted.svg" 100
fi
