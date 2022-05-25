#!/usr/bin/python3

from subprocess import CalledProcessError, check_call, check_output


def _pamixer(args):
    output = None
    try:
        output = check_output(['pamixer'] + args)
    except CalledProcessError as e:
        output = e.output

    return output.decode('utf-8')

def _sink():
    sinks_precedence = [
        'alsa_output.pci-0000_00_1f.3.hdmi-stereo',
        'alsa_output.pci-0000_00_1f.3.analog-stereo',
    ]
    sinks_list = _pamixer(['--list-sinks'])
    for potential_sink in sinks_precedence:
        if potential_sink in sinks_list:
            return potential_sink
    return None

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
