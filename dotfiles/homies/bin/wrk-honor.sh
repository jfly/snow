#!/usr/bin/env bash

set -e

function terminalOn() {
    CMD=$1
    WORKSPACE=$2

    alacritty --class "send to $WORKSPACE" -e "shtuff" new "$CMD" &
    sleep 0.1 # slow down spawning terminals so windows get positioned (hopefully) deterministically
}

sudo systemctl start docker
cd ~/src/github.com/joinhonor/external-api
terminalOn "make run" "be"
terminalOn $'docker compose up -d database\nshtuff-as-pwd' "be"
terminalOn "./pythonenv vim" "be"

cd ~/src/github.com/joinhonor/external-web
# terminalOn "make run" "fe"
terminalOn "shtuff-as-pwd" "fe"
terminalOn "./pythonenv vim" "fe"
