#!/usr/bin/env bash

function getShell() {
    getent passwd $USER | cut -d: -f7
}

function startOn() {
    CMD=$1
    WORKSPACE=$2

    termite -d $DIR -r "send to $WORKSPACE" -e "spawn-and-stuff $(getShell) \"$CMD\"" &
    sleep 0.1 # slow down spawning termites so things don't behave intermittently
}

DIR=~/gitting/worldcubeassociation.org/WcaOnRails/
startOn $'bin/rails s\n' "wrk"

DIR=~/gitting/worldcubeassociation.org/
startOn $'sudo systemctl start mysqld\n' "wrk"
startOn $'vim\n' "wrk"
