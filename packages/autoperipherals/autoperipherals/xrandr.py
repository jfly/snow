import shlex
import base64
import logging
import subprocess
from dataclasses import dataclass
import pyedid
from typing import Any
from Xlib.display import Display as XDisplay
from Xlib.ext.randr import PROPERTY_RANDR_EDID
from Xlib.ext import randr
import enum

logger = logging.getLogger(__name__)


class Rotation(str, enum.Enum):
    left = "left"
    right = "right"
    normal = "normal"
    inverted = "inverted"


class Connection(enum.Enum):
    CONNECTED = randr.Connected
    DISCONNECTED = randr.Disconnected
    UNKNOWN_CONNECTION = randr.UnknownConnection


@dataclass
class Coordinates:
    x: int
    y: int
    width: int
    height: int

    def contains(self, x: int, y: int) -> bool:
        return self.x <= x < self.x + self.width and self.y <= y < self.y + self.height


@dataclass
class Display:
    name: str  # something like 'DP-3-2'
    raw_edid: bytes | None

    @property
    def edid_hex(self) -> str | None:
        if self.raw_edid is None:
            return None
        return base64.b64encode(self.raw_edid).decode()

    edid: pyedid.Edid | None
    is_connected: bool
    is_active: bool

    # Currently read-only. Ideally we'd be able to apply this as well.
    coordinates: Coordinates | None

    # This is kind of weird: we don't currently support reading these values,
    # we only support setting them. Ideally we'd make the right queries to Xlib
    # to figure out these values.
    is_primary: bool = False
    left_of: "Display | None" = None
    right_of: "Display | None" = None
    rotation: Rotation = Rotation.normal


def get_edid(d: XDisplay, output: Any) -> tuple[bytes, pyedid.Edid]:
    """
    (copied from https://github.com/evocount/display-management/blob/v0.0.2/displaymanagement/output.py#L219)

    Returns (bytes, pyedid.Edid): The raw EDID of the monitor associated with this output, and the parsed `pyedid.Edid`.

    Throws:
        ResourceError
            If the output does not have an EDID property exposed
    """
    EDID_ATOM = d.intern_atom(PROPERTY_RANDR_EDID)
    EDID_TYPE = 19
    EDID_LENGTH = 128
    edid_info = d.xrandr_get_output_property(
        output, EDID_ATOM, EDID_TYPE, 0, EDID_LENGTH
    )

    raw_edid = bytes(edid_info._data["value"])
    return raw_edid, pyedid.parse_edid(raw_edid)


class XRandr:
    _display_by_name: dict[str, Display]

    def __init__(self):
        self.refresh()

    def refresh(self):
        displays: list[Display] = []

        d = XDisplay()
        info = d.screen()
        window = info.root

        resources = randr.get_screen_resources(window)
        for output_id in resources.outputs:
            params = d.xrandr_get_output_info(output_id, resources.config_timestamp)
            connection = Connection(params.connection)
            is_connected = connection == Connection.CONNECTED
            is_active = is_connected and bool(params.crtc)
            raw_edid, edid = get_edid(d, output_id) if is_connected else (None, None)

            crtc_id: int = params.crtc
            if crtc_id == 0:
                coordinates = None
            else:
                crtc_info = d.xrandr_get_crtc_info(crtc_id, resources.config_timestamp)
                coordinates = Coordinates(
                    x=crtc_info.x,
                    y=crtc_info.y,
                    width=crtc_info.width,
                    height=crtc_info.height,
                )

            displays.append(
                Display(
                    name=params.name,
                    raw_edid=raw_edid,
                    edid=edid,
                    is_connected=is_connected,
                    is_active=is_active,
                    coordinates=coordinates,
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

    def get_displays_where_mouse_is(self) -> list[Display]:
        info = XDisplay().screen()
        pointer = info.root.query_pointer()

        displays: list[Display] = []
        for display in self.connected_displays:
            if display.coordinates is None:
                continue

            if display.coordinates.contains(pointer.root_x, pointer.root_y):
                displays.append(display)

        return displays
