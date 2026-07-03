{
  lib,
  config,
  pkgs,
  ...
}:
let
  port = config.services.sonarr.settings.server.port;
  fflewddurIp = builtins.readFile ../../../vars/shared/zerotier-ip-fflewddur-manman/ip/value;
in
{
  services.sonarr = {
    enable = true;
    group = "media";

    settings = {
      auth.method = "External";
    };
  };

  snow.services.sonarr.proxyPass = "http://${config.vpnNamespaces.wg.namespaceAddress}:${toString port}";

  systemd.services.sonarr = {
    vpnConfinement = {
      enable = true;
      vpnNamespace = "wg";
    };
    unitConfig = {
      RequiresMountsFor = "/mnt/media";
    };
  };

  vpnNamespaces.wg.portMappings = [
    {
      from = port;
      to = port;
      protocol = "tcp";
    }
  ];

  # Sonarr doesn't seem to have good support for connecting to things over IPv6 [0].
  # I haven't checked Radarr.
  # As a workaround, set up a IPv4 -> IPv6 proxy locally for the needed
  # services.
  # [0]: https://github.com/Sonarr/Sonarr/issues/7534
  networking.extraHosts = ''
    ${config.vpnNamespaces.wg.bridgeAddress} jellyfin.m
  '';
  networking.firewall.interfaces.wg-br.allowedTCPPorts = [
    443
  ];
  systemd.services.jellyfin-ipv4-proxy = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    script = ''
      exec ${lib.getExe pkgs.socat} TCP4-LISTEN:443,fork,reuseaddr,bind=${config.vpnNamespaces.wg.bridgeAddress} TCP6:[${fflewddurIp}]:443
    '';
    serviceConfig = {
      Type = "exec";
      Restart = "on-failure";
    };
  };
}
