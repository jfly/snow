#!/bin/bash

# Copied from https://aur.archlinux.org/packages/volnoti-brightness-git/
BRIGHTNESS=$(</sys/class/backlight/intel_backlight/brightness)
MAX_BRIGHTNESS=$(</sys/class/backlight/intel_backlight/max_brightness)
PERCENT=$(echo "$BRIGHTNESS*100/$MAX_BRIGHTNESS" | bc)

# http://stackoverflow.com/a/3355423
DIR=$(dirname "$0")
volnoti-show -s $DIR/img/display-brightness-symbolic.svg $PERCENT
