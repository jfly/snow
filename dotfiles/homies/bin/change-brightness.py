#!/usr/bin/env python3

import sys

MIN_BRIGHTNESS_PERCENTAGE = 5

if len(sys.argv) != 2 or '-h' in sys.argv or '--help' in sys.argv:
    print('Pass a single argument to change the brightness. It can be either an absolute value or percentage, or you can use + or - to incrementally change the brightness. Try 5, 5+, 5-, 5%, 5%+, and 5%-.')
    sys.exit(1)

new_brightness = sys.argv[1]
delta = None

if new_brightness.endswith("+"):
    new_brightness = new_brightness[:-1]
    delta = 1

if new_brightness.endswith("-"):
    new_brightness = new_brightness[:-1]
    delta = -1

max_brightness = None
with open("/sys/class/backlight/intel_backlight/max_brightness") as f:
    max_brightness = int(f.read().strip())
min_brightness = MIN_BRIGHTNESS_PERCENTAGE * max_brightness / 100.

if new_brightness.endswith("%"):
    percentage = int(new_brightness[:-1])
    new_brightness = percentage * max_brightness / 100.
else:
    new_brightness = int(new_brightness)

if delta:
    brightness = None
    with open("/sys/class/backlight/intel_backlight/brightness") as f:
        brightness = int(f.read().strip())
    new_brightness = brightness + delta*new_brightness

if new_brightness < min_brightness:
    print("Won't set brightness lower than %s" % min_brightness)
    new_brightness = min_brightness

if new_brightness > max_brightness:
    print("Won't set brightness higher than %s" % max_brightness)
    new_brightness = max_brightness

with open("/sys/class/backlight/intel_backlight/brightness", "w") as f:
    f.write(str(int(new_brightness)))
