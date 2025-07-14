{ config, ... }:
{
  services.data-mesher.settings.host.names = [ "ospi" ];
  services.nginx.virtualHosts."ospi.${config.snow.tld}" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://ospi.ec:8080";
    };
  };
}
