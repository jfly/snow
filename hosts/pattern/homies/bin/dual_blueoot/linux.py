import configparser
from pathlib import Path
from typing import List

from .types import (
    BleKey,
    BluetoothDevice,
    IdentityResolvingKey,
    LocalSignatureKey,
    LongTermKey,
    MacAddress,
)
from .util import chunkify

BLUETOOTH_DIR = Path("/var/lib/bluetooth")


def get_local_bluetooth_adapters() -> List[MacAddress]:
    """
    Finds all locally attached bluetooth adapters. Returns their MAC addresses.
    """
    return [MacAddress(f.name) for f in BLUETOOTH_DIR.iterdir()]


def to_bytes(hex_str: str):
    assert len(hex_str) % 2 == 0
    return bytes(int("".join(hexed), 16) for hexed in chunkify(hex_str, 2))


def get_devices(adapter: MacAddress) -> list[BluetoothDevice]:
    adapter_dir = BLUETOOTH_DIR / adapter.format(caps=True, separator=":")
    devices = []
    for mac_address_dir in adapter_dir.iterdir():
        if not MacAddress.is_valid_mac_address(mac_address_dir.name):
            continue

        config = configparser.ConfigParser()
        config.optionxform = lambda optionstr: str(
            optionstr
        )  # Preserve the case of the option names
        info_path = mac_address_dir / "info"
        with open(info_path, "r") as f:
            config.read_file(f)

        general_section = config["General"]
        description = general_section["Name"]

        link_key = None
        if "LinkKey" in config:
            link_key_section = config["LinkKey"]
            link_key = to_bytes(link_key_section["Key"])
        elif (
            general_section["SupportedTechnologies"] == "LE;"
            and "LongTermKey" in config
        ):
            long_term_key_section = config["LongTermKey"]
            link_key = BleKey(
                long_term_key=LongTermKey(
                    key=to_bytes(long_term_key_section["Key"]),
                    key_length=int(long_term_key_section["EncSize"]),
                    rand=int(long_term_key_section["Rand"]),
                    e_div=int(long_term_key_section["EDiv"]),
                ),
                identity_resolving_key=IdentityResolvingKey(
                    key=to_bytes(config["IdentityResolvingKey"]["Key"])
                ),
                local_signature_key=LocalSignatureKey(
                    key=to_bytes(config["LocalSignatureKey"]["Key"])
                ),
            )
        else:
            link_key = None  # :shrug:

        devices.append(
            BluetoothDevice(
                mac_address=MacAddress(mac_address_dir.name),
                link_key=link_key,
                description=description,
            )
        )

    return devices
