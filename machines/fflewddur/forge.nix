{ config, ... }:
{
  services.forgejo = {
    enable = true;
    settings = {
      server.ROOT_URL = config.snow.services.forge.baseUrl;
    };
  };

  snow.services.forge.proxyPass = "http://localhost:${toString config.services.forgejo.settings.server.HTTP_PORT}";
}
