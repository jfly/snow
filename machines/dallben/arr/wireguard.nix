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

  networking.nat = {
    enable = true;
    enableIPv6 = true;
    internalInterfaces = [ "wg-br" ];
  };
}
