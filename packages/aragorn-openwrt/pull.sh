#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"

scp -O -r root@aragorn:/etc/config files/etc/
