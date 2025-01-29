#!/usr/bin/env bash

# Consider porting this to `autoperipherals`.

set -euo pipefail

if xrandr | grep -Po '[^ ]+(?= connected)' | grep -v eDP-1 >/dev/null; then
    echo "External display is connected. Doing nothing."
    exit 0
fi

if grep -q close /proc/acpi/button/lid/*/state; then
    current_connections=$(nmcli -t connection show --active | cut -d : -f 1)
    if echo "$current_connections" | grep "^\(Cal 3\|Cal 3.5\|Cal\|Cal4\|Cal 5g\|Hen Wen\|Auto Ethernet\|Wired connection 1\)$" &>/dev/null; then
        echo "Ignoring lid close event because we're connected to: $current_connections"
    else
        echo "Lid is closed. Locking screen."
        slock
    fi
elif grep -q open /proc/acpi/button/lid/*/state; then
    echo "Lid is open. Doing nothing."
    exit 0
fi
