#!/usr/bin/python3

import subprocess


def _pamixer(args):
    p = subprocess.run(['pamixer', *args], text=True, stdout=subprocess.PIPE)
    return p.stdout

def volume():
    return int(_pamixer(['--get-volume']).strip())

def set_volume(new_volume):
    _pamixer(['--set-volume', str(new_volume)])

def increase_volume(delta):
    _pamixer(['--increase', str(delta)])

def decrease_volume(delta):
    _pamixer(['--decrease', str(delta)])

def is_muted():
    return _pamixer(['--get-mute']).strip() == "true"

def set_mute(mute):
    _pamixer(['--mute' if mute else '--unmute'])

def toggle_mute():
    _pamixer(['--toggle-mute'])
