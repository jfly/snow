{
  services.data-mesher.settings.host.names = [ "ospi" ];
  services.nginx.virtualHosts."ospi.mm" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://ospi.ec:8080";
    };
  };
}
