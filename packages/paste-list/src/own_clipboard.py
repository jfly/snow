#!/usr/bin/env python

import logging
import time

from Xlib import X, display, Xatom
from Xlib.protocol import event

logger = logging.getLogger(__name__)


def own_clipboard(generator, sel_name="CLIPBOARD"):
    d = display.Display()

    sel_atom = d.get_atom(sel_name)

    utf8_target = d.get_atom("UTF8_STRING")
    # map type atom -> data generator
    generator_by_target = {
        utf8_target: generator,
    }

    targets_atom = d.get_atom("TARGETS")

    # We must have a window to own a selection
    w = d.screen().root.create_window(0, 0, 10, 10, 0, X.CopyFromParent)

    # And to grab the selection we must have a timestamp, get one with
    # a property notify when we're anyway setting wm_name
    w.change_attributes(event_mask=X.PropertyChangeMask)
    w.set_wm_name("just-some-name")

    e = d.next_event()
    sel_time = e.time
    w.change_attributes(event_mask=0)

    # Grab the selection and make sure we actually got it
    w.set_selection_owner(sel_atom, sel_time)
    if d.get_selection_owner(sel_atom) != w:
        assert False, f"could not take ownership of {sel_name}"

    logger.info("took ownership of selection %s", sel_name)

    # The event loop, waiting for and processing requests
    while True:
        e = d.next_event()

        if e.type == X.SelectionRequest and e.owner == w and e.selection == sel_atom:
            client = e.requestor

            if e.property == X.NONE:
                logger.info("request from obsolete client!")
                client_prop = e.target  # per ICCCM recommendation
            else:
                client_prop = e.property

            target_name = d.get_atom_name(e.target)

            logger.info(
                "got request for %s, dest %s on %s %s",
                target_name,
                d.get_atom_name(client_prop),
                hex(client.id),
                client.get_wm_name(),
            )

            # Is the client asking for which types we support?
            if e.target == targets_atom:
                # Then respond with TARGETS and the type
                prop_value = [targets_atom, *generator_by_target.keys()]
                prop_type = Xatom.ATOM
                prop_format = 32

            # Request for the offered type
            elif e.target in generator_by_target:
                prop_value = generator_by_target[e.target]()
                prop_type = e.target
                prop_format = 8

            # Something else, tell client they can't get it
            else:
                logger.info("refusing conversion to %s", target_name)
                client_prop = X.NONE

            # Put the data on the dest window, if possible
            if client_prop != X.NONE:
                client.change_property(client_prop, prop_type, prop_format, prop_value)

            # And always send a selection notification
            ev = event.SelectionNotify(
                time=e.time,
                requestor=e.requestor,
                selection=e.selection,
                target=e.target,
                property=client_prop,
            )

            client.send_event(ev)

            # Done!

        elif e.type == X.SelectionClear and e.window == w and e.atom == sel_atom:
            logger.warning("lost ownership of selection %s", sel_name)
            return

        # A proper owner would also look for PropertyNotify here on
        # the selector's windows to implement INCR and waiting for
        # acknowledgement that the client has finished copying.


def not_too_often(func, too_often_seconds=0.1):
    """
    Prevent the given function from getting called more frequently than
    `too_often_seconds`.
    If the function is called a second time before `too_often_seconds` have
    passed, then we return the previous value.

    This is useful to hack around the fact that Chrome seems to request the
    clipboard 4 times (nearly simultaneously) when pasting.
    """

    last_call = (0, "")  # pair: (last_call_ts, last_value)

    def wrapper():
        nonlocal last_call
        last_call_ts, last_value = last_call
        now = time.time()
        if now - last_call_ts < too_often_seconds:
            return last_value
        else:
            last_call_ts = now
            last_value = func()
            last_call = (last_call_ts, last_value)
            return last_value

    return wrapper


def main():
    logging.basicConfig(level=logging.INFO)

    count = 0

    @not_too_often
    def generator() -> bytes:
        nonlocal count
        count += 1
        return f"paste {count}".encode("utf-8")

    own_clipboard(generator)


if __name__ == "__main__":
    main()
