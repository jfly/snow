{ flake, config, ... }:
let
  inherit (config.snow) services;
in
{
  imports = [
    flake.nixosModules.oauth2-proxies-nginx
  ];

  services.whoami = {
    enable = true;
    port = 41234;
  };

  services.data-mesher.settings.host.names = [ services.whoami.sld ];
  services.nginx.virtualHosts.${services.whoami.fqdn} = {
    enableACME = true;
    forceSSL = true;

    snow.oauth2 = {
      enable = true;
      snowService = services.whoami;
      allowedGroups = [ services.whoami.oauth2.groups.access ];
    };
    locations."/" = {
      proxyPass = "http://localhost:${toString config.services.whoami.port}";
    };
  };
}
