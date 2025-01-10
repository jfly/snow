#!/usr/bin/env python

import io
from typing import Self
import wgconfig
from ipaddress import (
    IPv4Address,
    IPv6Interface,
    IPv4Interface,
    IPv6Network,
    IPv4Network,
)
from tempfile import TemporaryDirectory
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


def find_offset(network: IPv4Network, used: set[IPv4Address]) -> int:
    for offset in range(1, 255):
        ipv6_network = network[offset]
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
        wg_info.vpn_network.ipv4,
        used=set(
            address.ip
            for node in wg_info.nodes.values()
            for address in node.addresses
            if address.version == 4
        ),
    )

    ipv4_address = wg_info.vpn_network.ipv4[offset]
    ipv6_address = wg_info.vpn_network.ipv6[offset]

    addresses = [
        IPv4Interface((ipv4_address, 32)),
        IPv6Network((ipv6_address, 128), strict=False),
    ]

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
@click.option(
    "--split-ip/--no-split-ip",
    default=False,
    help="Only send IP traffic destined for the 'site' through the VPN, rather than all traffic. Default: all traffic is sent through the VPN (so-called 'full' vpn)",
)
@click.option(
    "--split-dns/--no-split-dns",
    default=False,
    help="Whether to send all DNS traffic through the VPN, or only DNS 'controlled' by the VPN site. Requires a client with `systemd-resolved`: <https://systemd.io/RESOLVED-VPNS/>",
)
@click.option(
    "--split-all",
    is_flag=True,
    default=False,
    help="Enables --split-ip and --split-dns",
)
def conf(hostname: str, split_ip: bool, split_dns: bool, split_all: bool):
    wg_info = WgInfo.load()
    nodes = wg_info.nodes

    if split_all:
        split_ip = True
        split_dns = True

    # Unfortunately, Sonic/AT&T doesn't give us a stable the GUA IPv6 prefix.
    # See <https://forums.sonic.net/viewtopic.php?t=18132> for details.
    # What's funny is that right now we don't really need stable IP prefixes
    # (because we're not hosting any IPv6 services... yet).
    # However, we need a static prefix to set up a static route that directs traffic
    # to our VPN server (see commented out code in `routers/strider/files/etc/config/network`).
    #
    # Some ideas:
    #   1. We actually might be getting stable IPv6 prefixes from AT&T, but
    #      the "delegation" of those prefixes to the macvlan interfaces we added is not stable.
    #      I suspect this would not be an issue if we bypass the Arris
    #      gateway: <https://github.com/up-n-atom/8311>
    #   2. Could clients obtain IPs via SLAAC? <https://forum.netgate.com/topic/166781/wireguard-with-ipv6-slaac-addresses/14>
    #   3. Use NPT (network prefix translation) to completely hide our GUA prefix from the internal network.
    #      Seems like it would make some IPv6 zealots cry, but IMO it's a good
    #      option until we have an ISP that can provide a stable prefix.
    #   4. Use an IPv6 tunnel that will give a static prefix.
    #      [Hurricane Electric](https://tunnelbroker.net/) comes up in a lot of research.
    #      Downside: latency, bandwidth?
    #
    # For now, we've allocated some space in our personal ULA prefix for VPN clients,
    # and set up NAT so they can talk to the outside world.
    assert IPv6Interface("fda0:f78f:a59e:31::1/128") in nodes["fflewddur"].addresses
    assert IPv6Network("fda0:f78f:a59e::/48") in nodes["fflewddur"].allowed_ips

    if hostname not in nodes:
        raise click.ClickException(
            f"Could not find conf for {hostname}. Are you sure you've generated one?"
        )

    node = nodes[hostname]

    config = wgconfig.WGConfig()
    config.add_attr(None, "PrivateKey", decrypt(node.keypair.private_encrypted))
    for address in node.addresses:
        config.add_attr(None, "Address", str(address))

    # Keep in sync with `routers/strider/files/etc/config/network`.
    dns_servers = [
        "192.168.28.1",
        # TODO: How to support DNS over IPv6? Use a ULA for our DNS server?
        #       See notes above about dynamic IPv6 prefixes.
    ]
    if not split_dns:
        config.add_attr(None, "DNS", ", ".join(dns_servers), "# strider.ec")
    else:
        internal_domains = [
            # Keep in sync with `option domain` in `routers/strider/files/etc/config/dhcp`.
            "ec",
            "ramfly.net",
            # Legacy: we'll eventually move all of this to `ramfly.net`.
            "snow.jflei.com",
        ]
        # Format the domains for `resolvectl`: "~domain1 ~domain2 ...".
        formatted_domains = " ".join(f"~{domain}" for domain in internal_domains)
        formatted_dns_servers = " ".join(dns_servers)
        config.add_attr(
            None,
            "PostUp",
            f"resolvectl dns %i {formatted_dns_servers} && resolvectl domain %i {formatted_domains}",
        )

    for hostname, node in nodes.items():
        if node.endpoint is not None:
            config.add_peer(node.keypair.public, f"# {hostname}")

            if split_ip:
                for allowed_ip in node.allowed_ips:
                    config.add_attr(node.keypair.public, "AllowedIPs", allowed_ip)
            else:
                config.add_attr(
                    node.keypair.public,
                    "AllowedIPs",
                    "0.0.0.0/0",
                    "# Full (not split) VPN",
                )
                config.add_attr(
                    node.keypair.public,
                    "AllowedIPs",
                    "::/0",
                )

            config.add_attr(node.keypair.public, "Endpoint", node.endpoint)

    conf_buffer = io.StringIO()
    config.write_to_fileobj(conf_buffer)
    conf_raw = conf_buffer.getvalue()

    print(conf_raw, end="")


if __name__ == "__main__":
    main()
