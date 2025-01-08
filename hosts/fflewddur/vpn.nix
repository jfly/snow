{
  flake,
  config,
  lib,
  ...
}:

# This Wireguard "server" configuration is inspired by
# <https://wiki.nixos.org/wiki/WireGuard>
# We intentionally do not support forwarding internet (WAN) traffic.

let
  # Keep in sync with `routers/strider/files/etc/config/firewall`.
  port = 51820;
  wgNodeInfo = flake.lib.wg.nodes.${config.networking.hostName};
in
{
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking.firewall.allowedUDPPorts = [ port ];

  networking.wireguard.enable = true;
  networking.wireguard.interfaces = {
    wg0 = {
      ips = wgNodeInfo.addresses;
      listenPort = port;

      privateKeyFile = config.age.secrets.wg-private-key.path;

      # Generate new peers with `python -m tools.wg gen`.
      peers = lib.pipe flake.lib.wg.nodes [
        (lib.filterAttrs (hostname: nodeInfo: hostname != config.networking.hostName))
        (lib.mapAttrsToList (
          hostname: nodeInfo: {
            name = hostname;
            publicKey = nodeInfo.keypair.public;
            allowedIPs = nodeInfo.allowed_ips;
          }
        ))
      ];
    };
  };

  age.secrets.wg-private-key.rooterEncrypted = wgNodeInfo.keypair.private_encrypted;
}
