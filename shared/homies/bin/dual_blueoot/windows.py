import configparser
import pathlib
import subprocess
import tempfile
from dataclasses import dataclass
from typing import Dict, List

from .types import (
    BleKey,
    BluetoothDevice,
    IdentityResolvingKey,
    LocalSignatureKey,
    LongTermKey,
    MacAddress,
)


def get_only_element(arr):
    assert len(arr) == 1, f"Expected exactly 1 element in: {arr}"
    return arr[0]


@dataclass
class RegistryNode:
    parent_path: str
    name: str
    subnode_by_name: Dict[str, "RegistryNode"]
    value_by_name: Dict[str, bytes]


class Registry:
    def __init__(self, path_to_registry: pathlib.Path):
        self._path_to_registry = path_to_registry

    def read_path(self, path_in_registry):
        out = tempfile.mktemp(".reg")
        subprocess.check_call(
            [
                "reged",
                "-x",
                str(self._path_to_registry),
                "\\",
                path_in_registry,
                out,
            ],
            stdout=subprocess.DEVNULL,
        )
        with open(out, "r") as file:
            raw_reg_contents = file.read()
            # Skip the "Windows Registry Editor ..." first line.
            raw_reg_contents = raw_reg_contents.split("\n", 1)[1]
        config = configparser.ConfigParser()
        config.optionxform = lambda optionstr: str(
            optionstr
        )  # Preserve the case of the option names
        config.read_string(raw_reg_contents, str(self._path_to_registry))

        node_by_path = {}
        for path, section in config.items():
            path_parts = path.split("\\")
            parent_path = "\\".join(path.split("\\")[:-1])
            name = path_parts[-1]
            node_by_path[path] = RegistryNode(
                parent_path=parent_path,
                name=name,
                subnode_by_name={},
                value_by_name=self._parse_section_values(section),
            )

        # Build a tree by stitching the child nodes to their parent nodes.
        root_nodes = {}
        for path, node in node_by_path.items():
            if node.parent_path not in node_by_path:
                root_nodes[path] = node
            else:
                node_by_path[node.parent_path].subnode_by_name[node.name] = node

        root_keys = list(root_nodes.keys())
        root_keys.remove("DEFAULT")
        root_key = get_only_element(root_keys)
        return root_nodes[root_key]

    def _parse_section_values(self, section: configparser.SectionProxy):
        parsed = {}
        for key, value in section.items():
            # For some reason, the keys always seem to start and end with quotation marks. Just remove them.
            assert key.startswith('"')
            assert key.endswith('"')
            key = key[1:-1]

            value = self._parse_value(value)
            parsed[key] = value

        return parsed

    def _parse_value(self, raw_value):
        raw_value = raw_value.lstrip('"')
        raw_value = raw_value.rstrip('"')

        if raw_value == "":
            return ""

        win_type, raw_data = raw_value.split(":", 1)
        if win_type == "hex":
            # Long enough values seem to get split into multiple lines. For example:
            #
            # [\\ControlSet001\Services\BTHPORT\Parameters\Devices\08ebed1b8695\DynamicCachedServices]
            # "00010000"=hex:35,62,09,00,00,0a,00,01,00,00,09,00,01,35,03,19,11,0b,09,00,04,\
            #  35,10,35,06,19,01,00,09,00,19,35,06,19,00,19,09,01,03,09,00,05,35,03,19,10,\
            #  02,09,00,06,35,09,09,65,6e,09,00,6a,09,01,00,09,00,08,08,ff,09,00,09,35,08,\
            #  35,06,19,11,0d,09,01,03,09,01,00,25,0a,41,32,44,50,20,53,69,6e,6b,00,09,03,\
            #  11,09,00,01
            #
            # Here we remove the backslash and newline characters to turn this into one line.
            # Astute readers may notice that there are also some spaces at
            # the start of the newlines. configparser seems to handle those
            # for us, though.
            one_line = raw_data.replace("\n", "").replace("\\", "")
            value = bytes(int(hex_pair, 16) for hex_pair in one_line.split(","))
        elif win_type == "hex(b)":
            # From https://en.wikipedia.org/wiki/Windows_Registry#.REG_files:
            # hex(b):<QWORD value (as comma-delimited list of 8 hexadecimal values, in little endian byte order)>
            values = raw_data.split(",")[::-1]
            assert len(values) == 8
            value = int("".join(values), 16)
        elif win_type == "dword":
            value = int(raw_data, 16)
        elif win_type == "Fingerprint":
            assert False  # TODO: implement?
        else:
            assert False, f"Unrecognized type: {win_type}"

        return value


class Windows:
    def __init__(self, path_to_registry: pathlib.Path):
        self._registry = Registry(path_to_registry)
        devices_path = r"ControlSet001\Services\BTHPORT\Parameters\Devices"
        self._devices_node = self._registry.read_path(devices_path)

    def _get_device_name(self, mac_address):
        device_node = self._devices_node.subnode_by_name[
            mac_address.format(caps=False, separator="")
        ]
        name = device_node.value_by_name["Name"]
        # Remove null terminator
        assert name[-1] == 0
        name = name[:-1]
        return name.decode("utf8")

    def get_devices(self, adapter: MacAddress) -> List[BluetoothDevice]:
        keys_path = rf"ControlSet001\Services\BTHPORT\Parameters\Keys"
        keys_node = self._registry.read_path(keys_path)
        adapter_node = keys_node.subnode_by_name[
            adapter.format(caps=False, separator="")
        ]

        devices = []

        # Search for non-BLE devices.
        for value_name, value in adapter_node.value_by_name.items():
            if not MacAddress.is_valid_mac_address(value_name):
                continue

            mac_address = MacAddress(value_name)
            device = BluetoothDevice(
                mac_address=mac_address,
                link_key=value,
                description=self._get_device_name(mac_address),
            )
            devices.append(device)

        # Search for BLE devices. They're stored in a completely different way on Windows.
        for key, node in adapter_node.subnode_by_name.items():
            if not MacAddress.is_valid_mac_address(key):
                continue

            mac_address = MacAddress(key)
            link_key = BleKey(
                long_term_key=LongTermKey(
                    key=node.value_by_name["LTK"],
                    key_length=node.value_by_name["KeyLength"],
                    rand=node.value_by_name["ERand"],
                    e_div=node.value_by_name["EDIV"],
                ),
                identity_resolving_key=IdentityResolvingKey(
                    key=node.value_by_name["IRK"]
                ),
                local_signature_key=LocalSignatureKey(key=node.value_by_name["CSRK"]),
            )
            device = BluetoothDevice(
                mac_address=mac_address,
                link_key=link_key,
                description=self._get_device_name(mac_address),
            )
            devices.append(device)

        return devices
