# TODO: investigate clan's mesh VPN instead: https://docs.clan.lol/guides/mesh-vpn/
# If it works out, remove:
#  - this file
#  - tools/wg.py
#  - lib/wg

{
}

# {
#   flake,
#   config,
#   lib,
#   pkgs,
#   ...
# }:
#
# # This Wireguard "server" configuration is inspired by
# # <https://wiki.nixos.org/wiki/WireGuard>, but with:
# #   - IPv4 support that doesn't end up double NAT-ed and
# #   - IPv6 support that we unfortunately NAT (see "IPv6 prefix" in `tools/wg.py`
# #     for details on why we're NAT-ing).
#
# let
#   # Keep in sync with `routers/strider/files/etc/config/firewall`.
#   port = 51820;
#   wgInfo = flake.lib.wg;
#   wgNodeInfo = wgInfo.nodes.${config.networking.hostName};
#   # Good luck remembering to change this if you provision a new machine.
#   # Hopefully the need for NAT disappears before then.
#   ethIntf = "enp5s0";
#   ipv6Nat = "${pkgs.iptables}/bin/ip6tables --table nat --source ${wgInfo.vpn_network.ipv6} --out-interface ${ethIntf} --jump MASQUERADE";
# in
# {
#   boot.kernel.sysctl = {
#     "net.ipv4.ip_forward" = 1;
#     "net.ipv6.conf.all.forwarding" = 1;
#   };
#
#   networking.firewall.allowedUDPPorts = [ port ];
#
#   networking.wireguard.enable = true;
#   networking.wireguard.interfaces = {
#     wg0 = {
#       ips = wgNodeInfo.addresses;
#       listenPort = port;
#
#       postSetup = ''
#         ${ipv6Nat} --append POSTROUTING
#       '';
#       postShutdown = ''
#         ${ipv6Nat} --delete POSTROUTING
#       '';
#
#       privateKeyFile = config.age.secrets.wg-private-key.path;
#
#       # Generate new peers with `python -m tools.wg gen`.
#       peers = lib.pipe flake.lib.wg.nodes [
#         (lib.filterAttrs (hostname: nodeInfo: hostname != config.networking.hostName))
#         (lib.mapAttrsToList (
#           hostname: nodeInfo: {
#             name = hostname;
#             publicKey = nodeInfo.keypair.public;
#             allowedIPs = nodeInfo.allowed_ips;
#           }
#         ))
#       ];
#     };
#   };
#
#   age.secrets.wg-private-key.rooterEncrypted = wgNodeInfo.keypair.private_encrypted;
# }
