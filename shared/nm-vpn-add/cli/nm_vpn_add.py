#!/usr/bin/env python

import re
import hashlib
import argparse
import subprocess
from typing import Dict
from typing import Optional
from typing import List
from pathlib import Path
import logging

logger = logging.getLogger(__name__)


def nmcli(*args: str):
    output = subprocess.check_output(["nmcli", *args], text=True)
    return output


def list_connections(conn_type: str) -> List[str]:
    suffix = f":{conn_type}"
    connections = []
    for connection in nmcli("-g", "name,type", "connection", "show").split("\n"):
        if connection.endswith(suffix):
            connections.append(connection.removesuffix(suffix))

    return connections


def hash_files(*files: Optional[Path]) -> str:
    m = hashlib.sha256()
    for file in files:
        if file is None:
            continue
        m.update(file.read_bytes())
    return m.hexdigest()[:7]


def get_connection_settings(connection_uuid: str) -> Dict[str, str]:
    settings: Dict[str, str] = {}
    raw_settings = nmcli("connection", "show", "uuid", connection_uuid)
    for setting in raw_settings.splitlines():
        key, value = setting.split(":", maxsplit=1)
        value = value.strip()
        settings[key] = value

    return settings


def set_passphrase(connection_uuid: str, passphrase: Path):
    settings = get_connection_settings(connection_uuid)

    # Set cert-pass-flags to 0. This is necessary for networkmanager to use the
    # cert-pass we're going to set in a moment. If we don't make this change,
    # then it defaults to 1 ("agent-owned") which means we'll get prompted for
    # a passphrase the first time we connect.
    # See
    # https://developer-old.gnome.org/NetworkManager/stable/secrets-flags.html
    # for an explanation of these settings.
    vpn_data = settings["vpn.data"]
    vpn_data = vpn_data.replace("cert-pass-flags = 1", "cert-pass-flags = 0")
    nmcli("connection", "modify", "uuid", connection_uuid, "vpn.data", vpn_data)

    cert_pass = passphrase.read_text().strip()
    nmcli(
        "connection",
        "modify",
        "uuid",
        connection_uuid,
        "vpn.secrets",
        f"cert-pass={cert_pass}",
    )


def enable_split_tunnel(connection_uuid: str):
    nmcli("connection", "modify", "uuid", connection_uuid, "ipv4.never-default", "true")


def add_connection(ovpn: Path):
    success_msg = nmcli("connection", "import", "type", "openvpn", "file", str(ovpn))
    success_re = re.compile(r"Connection '.*' \((.*)\) successfully added.")
    match = success_re.match(success_msg)
    assert match, f"Error adding connection: {success_msg}"
    connection_uuid = match.group(1)
    return connection_uuid


def rename_connection(connection_uuid: str, new_name: str):
    nmcli("connection", "modify", "uuid", connection_uuid, "connection.id", new_name)


def add_with_passphrase(ovpn: Path, passphrase: Optional[Path], force: bool):
    connection_name = f"{ovpn.stem}-{hash_files(ovpn, passphrase)}"
    if connection_name in list_connections("vpn"):
        if force:
            logger.info(
                "Found existing connection %s. --force was specified, so I'm going to delete it and add a new one.",
                ovpn.stem,
            )
            nmcli("connection", "delete", "id", connection_name)
        else:
            logger.info(
                "Skipping adding %s because connection %s already exists. Use --force to replace it.",
                ovpn.stem,
                connection_name,
            )
            return

    connection_uuid = add_connection(ovpn)
    try:
        if passphrase is not None:
            set_passphrase(connection_uuid, passphrase)
        enable_split_tunnel(connection_uuid)
        rename_connection(connection_uuid, connection_name)
    except:
        logger.warning(
            "Something went wrong! Deleting partially created connection: %s",
            connection_uuid,
        )
        nmcli("connection", "delete", "uuid", connection_uuid)
        raise

    logger.info(
        "Successfully created vpn connection %s (%s)", connection_name, connection_uuid
    )


def main():
    logging.basicConfig(level=logging.INFO)

    parser = argparse.ArgumentParser()
    parser.add_argument("ovpn_file", type=Path)
    parser.add_argument("passphrase_file", type=Path, nargs="?")
    parser.add_argument("--force", action="store_true")

    args = parser.parse_args()
    add_with_passphrase(args.ovpn_file, args.passphrase_file, force=args.force)


if __name__ == "__main__":
    main()
