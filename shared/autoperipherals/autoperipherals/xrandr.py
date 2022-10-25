import re
import subprocess
from dataclasses import dataclass


@dataclass
class Display:
    name: str  # something like 'DP-3-2'
    is_connected: bool
    is_active: bool


DISPLAY_RE = re.compile(r"^(\S+) (connected|disconnected) (.+)$")


@dataclass
class RawDisplayInfo:
    name: str  # something like 'DP-3-2'
    connected: str  # connected|disconnected
    info: str  # something like ' primary 2560x1440+2240+0 (normal left inverted right x axis y axis) 597mm x 336mm'
    modes: list[str]  # things like '   2560x1440     59.95*+'

    def cook(self) -> Display:
        return Display(
            name=self.name,
            is_connected={
                "connected": True,
                "disconnected": False,
            }[self.connected],
            is_active=any("*" in mode for mode in self.modes),
        )


class XRandr:
    _display_by_name: dict[str, Display]

    def __init__(self):
        self.refresh()

    def refresh(self):
        output = subprocess.check_output(["xrandr"], text=True)

        raw_displays: list[RawDisplayInfo] = []
        for line in output.splitlines():
            if line.startswith("Screen"):
                continue
            elif match := DISPLAY_RE.match(line):
                raw_display = RawDisplayInfo(
                    name=match.group(1),
                    connected=match.group(2),
                    info=match.group(3),
                    modes=[],
                )
                raw_displays.append(raw_display)
            else:
                raw_displays[-1].modes.append(line)

        displays = [raw_display.cook() for raw_display in raw_displays]
        self._display_by_name = {display.name: display for display in displays}

    def apply(self):
        args = ["xrandr"]
        for display in self._display_by_name.values():
            args.extend(
                [
                    "--output",
                    display.name,
                    "--preferred" if display.is_active else "--off",
                ]
            )

        subprocess.check_output(args)

    @property
    def connected_displays(self) -> list[Display]:
        return [d for d in self._display_by_name.values() if d.is_connected]
