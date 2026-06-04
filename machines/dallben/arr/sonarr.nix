{
  lib,
  config,
  pkgs,
  ...
}:
let
  port = config.services.sonarr.settings.server.port;
  fflewddurIp = builtins.readFile ../../../vars/per-machine/fflewddur/zerotier/zerotier-ip/value;
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
  #
  # Note: this breaks IPv4 jellyfin.m outside of the network namespace. That's
  # fine, as IPv6 still works (thanks to Happy Eyeballs).
  networking.extraHosts = ''
    127.0.0.1 jellyfin.m
  '';
  systemd.services.jellyfin-ipv4-proxy = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    vpnConfinement = {
      enable = true;
      vpnNamespace = "wg";
    };

    script = ''
      exec ${lib.getExe pkgs.socat} TCP4-LISTEN:443,fork,reuseaddr TCP6:[${fflewddurIp}]:443
    '';
    serviceConfig = {
      Type = "exec";
      Restart = "on-failure";
    };
  };
}
