#!/usr/bin/env bash

if grep -q close /proc/acpi/button/lid/*/state; then
    if nmcli -t connection show --active | cut -d : -f 1 | grep "^\(Honor\|Honor Ethernet\|Cal 3\|Cal 3.5\|Cal\|Hen Wen\|Auto Ethernet\|Wired connection 1\)$" &>/dev/null; then
        echo "Ignoring lid close event because we're connected to: $(nmcli -t connection show --active | cut -d : -f 1)"
    else
        echo "Lid is closed. Locking screen."
        slock
    fi
elif grep -q open /proc/acpi/button/lid/*/state; then
    echo "Lid is open. Doing nothing."
fi
