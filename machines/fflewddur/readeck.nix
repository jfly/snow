{ config, ... }:
let
  inherit (config.snow) services;
in
{
  clan.core.vars.generators.readeck-env = {
    files."env" = { };
    script = ''
      echo "READECK_SECRET_KEY=$(openssl rand -base64)" 48 >> $out/env
    '';
  };

  services.readeck = {
    enable = true;
    settings = {
      server = {
        port = 11410;
        trusted_proxies = [ "127.0.0.1" ];
      };
    };
    environmentFile = config.clan.core.vars.generators.readeck-env.files."env".path;
  };

  services.data-mesher.settings.host.names = [ services.readeck.sld ];
  services.nginx.virtualHosts.${services.readeck.fqdn} = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${builtins.toString config.services.readeck.settings.server.port}";
    };
  };
}
