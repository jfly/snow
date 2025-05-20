{
  services.nginx.virtualHosts."healthcheck.snow.jflei.com" = {
    locations."/".extraConfig = ''
      default_type text/plain;
      return 200 'all good here!';
    '';
  };
}
