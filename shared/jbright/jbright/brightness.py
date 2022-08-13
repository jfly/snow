from typing import Dict
import dataclasses
import subprocess
import logging
import csv

MIN_BRIGHTNESS_PERCENTAGE = 5

def _brightnessctl(args):
    p = subprocess.Popen(
        ["brightnessctl", "--machine-readable", *args],
        text=True,
        stdout=subprocess.PIPE,
    )
    assert p.stdout
    results = list(csv.reader(p.stdout))
    p.wait()
    assert p.returncode == 0
    return results

@dataclasses.dataclass
class Device:
    name: str
    type: str
    current_brightness: int
    max_brightness: int

    @classmethod
    def from_csv_row(cls, row):
        device_name, device_type, current_brightness, _percentage_brightness, max_brightness = row
        return cls(
            name=device_name,
            type=device_type,
            current_brightness=int(current_brightness),
            max_brightness=int(max_brightness),
        )

    def set(self, value: str):
        if "-" in value:
            value = value.replace("-", "")
            new_percentage_brightness = self.percentage_brightness - int(value.removesuffix("%"))
        elif "+" in value:
            value = value.replace("+", "")
            new_percentage_brightness = self.percentage_brightness + int(value.removesuffix("%"))
        else:
            new_percentage_brightness = int(value.removesuffix("%"))

        if new_percentage_brightness < MIN_BRIGHTNESS_PERCENTAGE:
            logging.warning("Refusing to lower the brightness below %s%%", MIN_BRIGHTNESS_PERCENTAGE)
            new_percentage_brightness = MIN_BRIGHTNESS_PERCENTAGE

        if new_percentage_brightness > 100:
            logging.warning("Refusing to raise the brightness above 100%")
            new_percentage_brightness = 100

        _brightnessctl(["--device", self.name, "set", f"{new_percentage_brightness}%"])
        self.current_brightness = int((new_percentage_brightness * self.max_brightness) / 100)

    @property
    def percentage_brightness(self) -> float:
        return (100 * self.current_brightness) / self.max_brightness

class Devices():
    _devices: Dict[str, Device]

    def __init__(self):
        raw_device_infos = _brightnessctl(["--list"])
        self._devices = {
            device.name: device
            for device in (Device.from_csv_row(row) for row in raw_device_infos)
        }

        # For now, we're treaeting the first thing returned by brightnessctl as
        # the "default" device. Fortunately this works because python dicts
        # (now) preserve insertion order. Yay!
        self._default = next(iter(self._devices.values()))

    @property
    def default(self):
        return self._default

    def values(self):
        return self._devices.values()

    def __iter__(self):
        return iter(self._devices.values())

    def get(self, device_name: str):
        return self._devices[device_name]

def get_devices():
    return Devices()
