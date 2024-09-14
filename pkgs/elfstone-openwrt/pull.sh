#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"


scp -O -r root@elfstone:/etc/config files/etc/
