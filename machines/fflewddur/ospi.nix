{ config, ... }:
let
  inherit (config.snow) services;
in
{
  services.data-mesher.settings.host.names = [ services.ospi.sld ];
  services.nginx.virtualHosts.${services.ospi.fqdn} = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://ospi.ec:8080";
    };
  };
}
