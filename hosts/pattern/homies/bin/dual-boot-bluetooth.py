#!/usr/bin/env python

import os
import sys
import argparse
from typing import List
from pathlib import Path

from dual_blueoot import linux
from dual_blueoot.types import BluetoothDevice, MacAddress
from dual_blueoot.util import group_by
from dual_blueoot.windows import Windows


def require_root():
    if os.geteuid() != 0:
        print("You must run this script as root")
        sys.exit(1)


def diff_devices(
    left_description: str,
    left_devices: List[BluetoothDevice],
    right_description: str,
    right_devices: List[BluetoothDevice],
):
    """
    Prints out devices that exist in one list but not the other, and vice
    versa. Also identifies devices that are in both lists, but differ in some
    way.
    """
    found_diff = False

    left_device_by_mac = group_by(left_devices, key=lambda device: device.mac_address)
    right_device_by_mac = group_by(right_devices, key=lambda device: device.mac_address)

    left_missing = right_device_by_mac.keys() - left_device_by_mac.keys()
    right_missing = left_device_by_mac.keys() - right_device_by_mac.keys()

    intersection = right_device_by_mac.keys() & left_device_by_mac.keys()

    print(f"Found these devices in {right_description}, but not in {left_description}:")
    for mac in left_missing:
        found_diff = True
        right_device = right_device_by_mac[mac]
        print(f"\t{right_device}")

    print("")
    print(f"Found these devices in {left_description}, but not in {right_description}:")
    for mac in right_missing:
        found_diff = True
        left_device = left_device_by_mac[mac]
        print(f"\t{left_device}")

    print("")
    for mac in intersection:
        found_diff = True
        left_device = left_device_by_mac[mac]
        right_device = right_device_by_mac[mac]
        if left_device.link_key != right_device.link_key:
            print(
                f"Differing link keys!: {left_description} {left_device} which is not the same as {right_description} {right_device}"
            )

    print("")
    for mac in intersection:
        found_diff = True
        left_device = left_device_by_mac[mac]
        right_device = right_device_by_mac[mac]
        if left_device.link_key == right_device.link_key:
            print(
                f"Matching link keys!: {left_description} {left_device} which is the same as {right_description} {right_device}"
            )

    if not found_diff:
        print(
            "No devices missing or differing between {left_description} and {right_description}!"
        )


def main():
    require_root()

    adapter_macs = [
        adapter.mac_address for adapter in linux.get_local_bluetooth_adapters()
    ]
    if len(adapter_macs) == 1:
        (adapter_mac,) = adapter_macs
    else:
        adapter_mac = None

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--adapter",
        choices=adapter_macs,
        default=adapter_mac,
        help="Bluetooth adapter",
    )
    parser.add_argument(
        "--windows-registry",
        required=True,
        help="Path to Windows registry. How to decrypt a BitLocker partition and mount it...?",
    )

    args = parser.parse_args()

    if args.adapter is None:
        print("Adapter is required", file=sys.stderr)
        sys.exit(1)

    if args.windows_registry is None:
        print("Path to Windows registry is required", file=sys.stderr)
        sys.exit(1)

    adapter = MacAddress(args.adapter)
    path_to_windows_registry = Path(args.windows_registry)

    if not path_to_windows_registry.exists():
        print(
            f"Given Windows registry does not exist: {path_to_windows_registry}",
            file=sys.stderr,
        )
        sys.exit(1)

    linux_devices = linux.get_devices(adapter)
    windows = Windows(path_to_windows_registry)
    windows_devices = windows.get_devices(adapter)
    diff_devices("Windows", windows_devices, "Linux", linux_devices)


if __name__ == "__main__":
    main()
