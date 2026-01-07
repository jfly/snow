{ config, ... }:
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

  snow.services.readeck.proxyPass = "http://127.0.0.1:${toString config.services.readeck.settings.server.port}";
}
