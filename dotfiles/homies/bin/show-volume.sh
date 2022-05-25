#!/usr/bin/env bash

volume=`get_volume.py`
if echo "$volume" | grep Mute; then
    volnoti-show -m
else
    volnoti-show $volume
fi
