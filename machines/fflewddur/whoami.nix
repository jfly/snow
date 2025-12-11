{ flake, config, ... }:
let
  inherit (config.snow) services;
in
{
  imports = [
    flake.nixosModules.oauth2-proxies-nginx
  ];

  services.nginx.virtualHosts.${services.whoami.fqdn} = {
    snow.oauth2 = {
      enable = true;
      snowService = services.whoami;
      allowedGroups = [ services.whoami.oauth2.groups.access ];
    };
  };

  snow.services.whoami.proxyPass = "http://localhost:${toString config.services.whoami.port}";

  services.whoami = {
    enable = true;
    port = 41234;
  };
}
