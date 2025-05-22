#!/usr/bin/env bash

set -euo pipefail

# Change to the root of the repo.
cd "$(git rev-parse --show-toplevel)"

help() {
    echo "Usage: $0 [hostname]
" >/dev/stderr
}

hostname=""
dry_run=0
force=0
for i in "$@"; do
    case $i in
        --dry-run)
            dry_run=1
            ;;
        --force)
            force=1
            ;;
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

echo "Deploying to $hostname"

system=$(nix config show system)
flake_target=".#routers.${system}.${hostname}"

# Note: we use `deage.impureString` in these routers, which means we have to do
# impure builds. See it's docstring for ideas to get rid of it.
purity=("--impure")

# First, check if the version currently installed/running is already up to date?
#
desired_nix_version=$(nix eval "$flake_target" "${purity[@]}" --raw --apply 'r: r.hack-nix-version')
if actual_nix_version=$(ssh "$hostname" cat /etc/nix-build-version); then
    :
else
    if [ $force == 1 ]; then
        echo "Could not determine current version of $hostname. --force was specified, so I'm going to keep moving forward and see what happens."
        actual_nix_version="???"
    else
        echo "Could not determine current version of $hostname. Try again with --force to ignore."
        exit 1
    fi
fi

if [ "$desired_nix_version" = "$actual_nix_version" ]; then
    echo "It looks like $hostname is already up to date (running $actual_nix_version)."
    if [ $force == 1 ]; then
        echo "Continuing, since --force was specified."
    else
        echo "Not doing anything to it!"
        exit 0
    fi
fi

echo "It looks $hostname is out of date (desired $desired_nix_version, running: $actual_nix_version)"

# Basically copying
# https://openwrt.org/docs/guide-user/installation/sysupgrade.cli#command-line_instructions
result=$(nix build "$flake_target" --no-link --print-out-paths "${purity[@]}")
files=("$result"/*-sysupgrade.*)
file=${files[0]}
echo "Successfully built $file"
if [ $dry_run == 1 ]; then
    echo "Not actually deploying $file because we're doing a dry run"
else
    dest_filename=/tmp/firmware_image-sysupgrade
    scp -O "$file" "$hostname":$dest_filename
    ssh "$hostname" sysupgrade -v -n $dest_filename
fi
