#!/usr/bin/env python3

import screenlayout.xrandr
from screenlayout.auxiliary import Position, NORMAL, InadequateConfiguration

xrandr = None


def main():
    global xrandr
    xrandr = screenlayout.xrandr.XRandR()
    xrandr.load_from_x()

    outputs_by_name = xrandr.state.outputs
    connected_outputs = [
        output for output in outputs_by_name.values() if output.connected
    ]
    for output in outputs_by_name.values():
        # Disable the laptop screen if there's another output connected.
        if output.name == "eDP1" and len(connected_outputs) > 1:
            make_active = False
        else:
            make_active = output.connected
        activate_output(output, make_active=make_active)

    print(" ".join(xrandr.configuration.commandlineargs()))


def activate_output(output, make_active):
    output_config = xrandr.configuration.outputs[output.name]
    output_config.active = make_active
    if make_active:
        # Copied from
        # /usr/lib/python3.7/site-packages/screenlayout/widget.py
        # ARandRWidget::set_active
        output_config.position = Position((0, 0))

        virtual_state = xrandr.state.virtual
        for mode in output.modes:
            # determine first possible mode
            if mode[0] <= virtual_state.max[0] and mode[1] <= virtual_state.max[1]:
                first_mode = mode
                break
            else:
                raise InadequateConfiguration("Smallest mode too large for virtual.")
            output_config.mode = first_mode

            output_config.rotation = NORMAL


if __name__ == "__main__":
    main()
