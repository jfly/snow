import shlex
import logging
import subprocess
from dataclasses import dataclass
import pyedid
from typing import Any
from typing import Literal
from Xlib import display
from Xlib.ext.randr import PROPERTY_RANDR_EDID
from Xlib.ext import randr
import enum

logger = logging.getLogger(__name__)


class Connection(enum.Enum):
    CONNECTED = randr.Connected
    DISCONNECTED = randr.Disconnected
    UNKNOWN_CONNECTION = randr.UnknownConnection


@dataclass
class Display:
    name: str  # something like 'DP-3-2'
    edid: pyedid.Edid | None
    is_connected: bool
    is_active: bool

    # This is kind of weird: we don't currently support reading these values,
    # we only support setting them. Ideally we'd make the right queries to Xlib
    # to figure out these values.
    is_primary: bool = False
    left_of: "Display | None" = None
    right_of: "Display | None" = None
    rotation: Literal["normal", "left", "right", "inverted"] = "normal"


def get_edid(d: display.Display, output: Any) -> pyedid.Edid:
    """
    (copied from https://github.com/evocount/display-management/blob/v0.0.2/displaymanagement/output.py#L219)

    Returns the EDID of the monitor represented by the display

    Returns
    EDIDDescriptor
        The EDID info of the monitor associated with this output

    Throws
    ResourceError
        If the output does not have an EDID property exposed
    """
    EDID_ATOM = d.intern_atom(PROPERTY_RANDR_EDID)
    EDID_TYPE = 19
    EDID_LENGTH = 128
    edid_info = d.xrandr_get_output_property(
        output, EDID_ATOM, EDID_TYPE, 0, EDID_LENGTH
    )

    return pyedid.parse_edid(bytes(edid_info._data["value"]))


class XRandr:
    _display_by_name: dict[str, Display]

    def __init__(self):
        self.refresh()

    def refresh(self):
        displays: list[Display] = []

        d = display.Display()
        info = d.screen()
        window = info.root

        resources = randr.get_screen_resources(window)
        for output in resources.outputs:
            params = d.xrandr_get_output_info(output, resources.config_timestamp)
            connection = Connection(params.connection)
            is_connected = connection == Connection.CONNECTED
            is_active = is_connected and bool(params.crtc)
            edid = get_edid(d, output) if is_connected else None

            displays.append(
                Display(
                    name=params.name,
                    edid=edid,
                    is_connected=is_connected,
                    is_active=is_active,
                )
            )

        self._display_by_name = {display.name: display for display in displays}

    def apply(self):
        args = ["xrandr"]
        for display in self._display_by_name.values():
            args.extend(
                [
                    "--output",
                    display.name,
                    "--preferred" if display.is_active else "--off",
                    "--rotate",
                    display.rotation,
                ]
            )
            if display.is_primary:
                args.extend(["--primary"])
            if display.left_of is not None:
                args.extend(["--left-of", display.left_of.name])
            if display.right_of is not None:
                args.extend(["--right-of", display.right_of.name])

        logger.info("About to invoke xrandr: %s", shlex.join(args))
        subprocess.check_output(args)

    @property
    def connected_displays(self) -> list[Display]:
        return [d for d in self._display_by_name.values() if d.is_connected]
