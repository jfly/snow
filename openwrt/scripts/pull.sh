#!/usr/bin/env bash

set -euo pipefail

help() {
    echo "Usage: $0 [hostname]
" >/dev/stderr
}

hostname=""
for i in "$@"; do
    case $i in

        --help | -h)
            help
            exit 0
            ;;
        --* | -*)
            echo "Unknown option $i" >/dev/stderr
            echo "" >/dev/stderr
            help
            exit 1
            ;;
        *)
            if [ -n "$hostname" ]; then
                echo "You must specify exactly one hostname" >/dev/stderr
                echo "" >/dev/stderr
                help
                exit 1
            fi
            hostname=$i
            ;;
    esac
done

if [ -z "$hostname" ]; then
    echo "You must specify exactly one hostname" >/dev/stderr
    echo "" >/dev/stderr
    help
    exit 1
fi

echo "Pulling configuration from $hostname"

scp -O -r root@"$hostname":/etc/config files/etc/
