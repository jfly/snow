#!/usr/bin/env python3

import sys
import pa

if len(sys.argv) != 2 or '-h' in sys.argv or '--help' in sys.argv:
    print('Pass a single argument to change the volume. You can use + or - to incrementally change the volume. Try 5, 5+, 5-, and toggle-mute.')
    sys.exit(1)

arg = sys.argv[1]

if arg.endswith("+"):
    delta = int(arg[:-1])
    pa.increase_volume(delta)
elif arg.endswith("-"):
    delta = int(arg[:-1])
    pa.decrease_volume(delta)
elif arg == "toggle-mute":
    pa.toggle_mute()
else:
    volume = int(arg)
    pa.set_volume(volume)
