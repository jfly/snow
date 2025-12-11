{
  inputs,
  config,
  ...
}:
let
  wgConf = config.clan.core.vars.generators.wireguard-conf.files."wg.conf".path;
in
{
  imports = [ inputs.vpn-confinement.nixosModules.default ];

  clan.core.vars.generators.wireguard-conf = {
    prompts."wg.conf" = {
      persist = true;
      type = "multiline";
    };
  };

  vpnNamespaces.wg = {
    enable = true;
    wireguardConfigFile = wgConf;
    namespaceAddress = "172.20.0.1";
    namespaceAddressIPv6 = "fda0:f78f:a59e:20::1";
    bridgeAddress = "172.20.0.254";
    bridgeAddressIPv6 = "fda0:f78f:a59e:20::ff";
    accessibleFrom = [
      config.snow.subnets.colusa-trusted.ipv4
      config.snow.subnets.overlay.ipv6
    ];
  };

  # Allow communication *out* of the network namespace to our `accessibleFrom`
  # subnets. The reverse (traffic going into the namespace) works out of the
  # box because [`VPN-Confinment` sets up a
  # DNAT](https://github.com/Maroka-chan/VPN-Confinement/blob/08cdda8013611e874ac6d3d59d508e56dfee0405/modules/firewall-utils.nix#L16-L25)
  # Perhaps `VPN-Confinement` would be open to a PR adding this?
  networking.nat = {
    enable = true;
    enableIPv6 = true;
    internalInterfaces = [ "wg-br" ];
  };
}
