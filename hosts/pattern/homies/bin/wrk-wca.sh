#!/usr/bin/env bash

set -e

function terminalOn() {
    CMD=$1
    WORKSPACE=$2

    alacritty --class "send to $WORKSPACE" -e "shtuff" new "$CMD" &
    sleep 0.1 # slow down spawning termites so things don't behave intermittently
}

sudo systemctl start docker
docker start mysql-8 || docker run --name mysql-8 -e MYSQL_ALLOW_EMPTY_PASSWORD=yes -d --publish=3308:3306 mysql:8

cd ~/src/github.com/thewca/worldcubeassociation.org/WcaOnRails/
terminalOn "bin/rails s" "be"
terminalOn "sap" "be"
terminalOn "vim" "be"
