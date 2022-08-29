#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "$0")"

if [ "$EUID" -eq 0 ]; then
    echo "Do not run this script as root, instead run it as the non-root user you want to set up."
    exit 1
fi

doit() {
    git submodule update --init

    ## Install and configure most things.
    if [ -z "$SKIP_ACONFMGR" ]; then
        ./aconfmgr apply --yes
    fi

    ## Install some more things
    nix-env -irf my-nix '.*'

    ## Install even more things
    local home_manager
    home_manager=$(nix-build my-nix -A home-manager --no-out-link)
    "$home_manager/activate"

    ## Generate locales
    sudo locale-gen

    ## Install homies
    ./install
}

doit

echo ""
echo "Successfully bootstrapped your new Arch system. Happy Linuxing!"
