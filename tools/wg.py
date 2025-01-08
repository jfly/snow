#!/usr/bin/env python

from typing import Self
import wgconfig
from ipaddress import (
    IPv6Interface,
    IPv4Interface,
    IPv6Network,
    IPv4Network,
    IPv6Address,
)
from tempfile import NamedTemporaryFile, TemporaryDirectory
import click
import subprocess
import rich
from .encrypt import encrypt
from .encrypt import decrypt
from pathlib import Path
import sys
from pydantic import BaseModel


@click.group()
def main():
    pass


def root() -> Path:
    return Path(
        subprocess.check_output(
            ["git", "rev-parse", "--show-toplevel"], text=True
        ).strip()
    )


class Keypair(BaseModel):
    public: str
    private_encrypted: str


class Node(BaseModel):
    endpoint: str | None
    addresses: list[IPv4Interface | IPv6Interface]
    allowed_ips: list[IPv4Network | IPv6Network]
    keypair: Keypair


class VpnNetwork(BaseModel):
    ipv4: IPv4Network
    ipv6: IPv6Network


class WgInfo(BaseModel):
    nodes: dict[str, Node]
    vpn_network: VpnNetwork

    @staticmethod
    def path() -> Path:
        return root() / "lib/wg/wg.json"

    @classmethod
    def load(cls) -> Self:
        with cls.path().open("rt") as f:
            return cls.model_validate_json(f.read(), strict=True)

    def save(self):
        with TemporaryDirectory() as temp:
            temp = Path(temp) / "wg.json"
            temp.write_text(self.model_dump_json(indent=4) + "\n")
            temp.rename(self.path())


def wg_genkey() -> Keypair:
    cp = subprocess.run(["wg", "genkey"], stdout=subprocess.PIPE, text=True, check=True)
    private = cp.stdout.strip()

    cp = subprocess.run(
        ["wg", "pubkey"], input=private, stdout=subprocess.PIPE, text=True, check=True
    )
    public = cp.stdout.strip()

    return Keypair(
        private_encrypted=encrypt(private),
        public=public,
    )


def find_offset(network: IPv6Network, used: set[IPv6Address]) -> int:
    for offset in range(1, 255):
        ipv6_network = network[offset << 64]
        if ipv6_network not in used:
            return offset

    assert False, f"Could not find an available offset in {network}"


@main.command(
    help="Add a node to the cluster. Currently assumes you're adding a new host, rather than a new 'site'."
)
@click.argument("hostname")
def gen(hostname: str):
    wg_info = WgInfo.load()

    if hostname in wg_info.nodes:
        raise click.ClickException(f"{hostname!r} already found in {WgInfo.path()}")

    offset = find_offset(
        wg_info.vpn_network.ipv6,
        used=set(
            address.ip
            for node in wg_info.nodes.values()
            for address in node.addresses
            if address.version == 6
        ),
    )

    ipv6_interface = IPv6Interface((wg_info.vpn_network.ipv6[offset << 64], 64))
    ipv4_interface = IPv4Interface((wg_info.vpn_network.ipv4[offset], 32))
    addresses = [ipv6_interface, ipv4_interface]

    node = Node(
        # See comment above about adding a host vs a 'site'.
        endpoint=None,
        addresses=addresses,
        allowed_ips=addresses,
        keypair=wg_genkey(),
    )
    wg_info.nodes[hostname] = node

    wg_info.save()

    rich.print(
        f"[bold][green]Successfully generated Wireguard configuration for {hostname}[/green][/bold]",
        file=sys.stderr,
    )

    print("Next steps:")
    print("  1. Deploy fflewddur.")
    print("  2. Use the `conf` subcommand to print a WG conf file for the new client.")


@main.command()
@click.argument("hostname")
def conf(hostname: str):
    wg_info = WgInfo.load()
    nodes = wg_info.nodes

    # This is the GUA IPv6 prefix that Sonic (AT&T?) has assigned us. Unfortunately, there's
    # no guarantee it's stable. See <https://forums.sonic.net/viewtopic.php?t=18132> for details.
    #
    # TODO: figure out a better solution for this. Some ideas:
    #   1. Use NPT (network prefix translation) to completely hide our GUA prefix from the internal network.
    #      Seems like it would make some IPv6 zealots cry, but IMO it's a good
    #      option until we have an ISP that can provide a stable prefix.
    #   2. Reconfigure `dnsmasq` to not return GUAs for local hosts. I can't find a
    #      way to do this with `dnsmasq`, though. Perhaps they'd accept a patch?
    #      Also see [ULA is Broken (in Dual-stack Networks)](https://blogs.infoblox.com/ipv6-coe/ula-is-broken-in-dual-stack-networks/).
    #   3. Use an IPv6 tunnel that will give a static prefix.
    #      [Hurricane Electric](https://tunnelbroker.net/) comes up in a lot of research.
    #      Downside: latency, bandwidth?
    assert IPv6Network("2600:1700:a41a:381f::/64") in nodes["fflewddur"].allowed_ips

    if hostname not in nodes:
        raise click.ClickException(
            f"Could not find conf for {hostname}. Are you sure you've generated one?"
        )

    node = nodes[hostname]

    # Unfortunately, `wgconfig` requires a concrete file.
    # See <https://github.com/towalink/wgconfig/issues/8> for a feature
    # request to deal with file-like objects.
    with NamedTemporaryFile("wt", suffix=".conf") as conf_path:
        config = wgconfig.WGConfig(conf_path.name)
        config.add_attr(None, "PrivateKey", decrypt(node.keypair.private_encrypted))
        for address in node.addresses:
            config.add_attr(None, "Address", str(address))

        # Keep in sync with `routers/strider/files/etc/config/network`.
        config.add_attr(None, "DNS", "192.168.28.1", "# strider.ec")
        config.add_attr(None, "DNS", "fda0:f78f:a59e::1", "# strider.ec")

        for hostname, node in nodes.items():
            if node.endpoint is not None:
                config.add_peer(node.keypair.public, f"# {hostname}")
                for allowed_ip in node.allowed_ips:
                    config.add_attr(node.keypair.public, "AllowedIPs", allowed_ip)
                config.add_attr(node.keypair.public, "Endpoint", node.endpoint)

        config.write_file()
        conf_raw = Path(conf_path.name).read_text()

    print(conf_raw, end="")


if __name__ == "__main__":
    main()
