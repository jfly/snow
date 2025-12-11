{ config, ... }:
let
  inherit (config.snow) services;
  port = config.services.jellyseerr.port;
in
{
  services.jellyseerr.enable = true;

  services.data-mesher.settings.host.names = [ services.seerr.sld ];
  services.nginx.virtualHosts.${services.seerr.fqdn} = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://${config.vpnNamespaces.wg.namespaceAddress}:${toString port}";
    };
  };

  #<<< TODO: explain >>>
  networking.extraHosts = ''
    ${builtins.readFile ../../../vars/per-machine/fflewddur/zerotier/zerotier-ip/value} ${services.jellyfin.fqdn}
    ${builtins.readFile ../../../vars/per-machine/dallben/zerotier/zerotier-ip/value} ${services.radarr.fqdn} ${services.sonarr.fqdn}
  '';

  systemd.services.jellyseerr = {
    # Set `HOME` as a workaround for <https://github.com/Maroka-chan/VPN-Confinement/issues/36>.
    environment.HOME = config.services.jellyseerr.configDir;
    vpnConfinement = {
      enable = true;
      vpnNamespace = "wg";
    };
  };

  vpnNamespaces.wg.portMappings = [
    {
      from = port;
      to = port;
      protocol = "tcp";
    }
  ];

  snow.backup.paths = [
    config.services.jellyseerr.configDir
  ];
}
