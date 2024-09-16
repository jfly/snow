#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"

scp -O -r root@strider:/etc/config files/etc/
