#!/usr/bin/env python3

# Python code to set the state of the capslock key, idea from
#  https://askubuntu.com/questions/80254/how-do-i-turn-off-caps-lock-the-lock-not-the-key-by-command-line
# Modified by @jfly to match the command line arguments of numlockx.

import sys
import argparse
import ctypes

c_uchar = ctypes.c_char
from contextlib import contextmanager

XkbUseCoreKbd = 0x100  # See <X11/extensions/XKB.h>
LockMask = 1 << 1  # See <X11/X.h>

X11 = ctypes.cdll.LoadLibrary("libX11.so.6")
byteorder = sys.byteorder


class Display(ctypes.Structure):
    """opaque struct"""


# See <X11/extensions/XKBstr.h>
class XkbStateRec(ctypes.Structure):
    _fields_ = [
        ("count", c_uchar),
        ("locked_group", c_uchar),
        ("base_group", ctypes.c_ushort),
        ("latched_group", ctypes.c_ushort),
        ("mods", c_uchar),
        ("base_mods", c_uchar),
        ("latched_mods", c_uchar),
        ("locked_mods", c_uchar),
        ("compat_state", c_uchar),
        ("grab_mods", c_uchar),
        ("compat_grab_mods", c_uchar),
        ("lookup_mods", c_uchar),
        ("compat_lookup_mods", c_uchar),
        ("ptr_buttons", ctypes.c_ushort),
    ]


X11.XOpenDisplay.restype = ctypes.POINTER(Display)


def set_modifier(modifier, on):
    with open_display() as display:
        X11.XkbLockModifiers(
            display,
            ctypes.c_uint(XkbUseCoreKbd),
            ctypes.c_uint(modifier),
            ctypes.c_uint(modifier if on else 0),
        )


def get_modifier(modifier):
    with open_display() as display:
        xkbState = XkbStateRec()
        X11.XkbGetState(display, ctypes.c_uint(XkbUseCoreKbd), ctypes.pointer(xkbState))
        locked_mods = int.from_bytes(
            xkbState.locked_mods, byteorder=byteorder, signed=False
        )
        return locked_mods & modifier


@contextmanager
def open_display():
    display = X11.XOpenDisplay(ctypes.c_uint(0))
    yield display
    X11.XCloseDisplay(display)


def main():
    parser = argparse.ArgumentParser(description="Control the state of the caplock key")
    parser.add_argument("state", choices=["on", "off", "toggle", "get"])
    args = parser.parse_args()

    if args.state == "on":
        set_modifier(LockMask, True)
    elif args.state == "off":
        set_modifier(LockMask, False)
    elif args.state == "toggle":
        set_modifier(LockMask, not get_modifier(LockMask))
    elif args.state == "get":
        print("on" if get_modifier(LockMask) else "off")
    else:
        assert False


if __name__ == "__main__":
    main()
