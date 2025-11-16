{ config, ... }:
let
  inherit (config.snow) services;
in
{
  # TODO: expose publicly.
  # See
  # <https://immichframe.online/docs/getting-started/configuration#security>
  # and <https://github.com/immichFrame/ImmichFrame/issues/513>.

  services.data-mesher.settings.host.names = [ services.immichframe.sld ];
  services.nginx.virtualHosts.${services.immichframe.fqdn} = {
    enableACME = true;
    forceSSL = true;

    # https://wiki.nixos.org/wiki/Immich#Using_Immich_behind_Nginx
    locations."/" = {
      proxyPass = "http://localhost:${toString config.services.immichframe.port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
      extraConfig = ''
        client_max_body_size 50000M;
        proxy_read_timeout   600s;
        proxy_send_timeout   600s;
        send_timeout         600s;
      '';
    };
  };

  clan.core.vars.generators.immichframe-api-key = {
    prompts."api-key" = {
      description = ''
        API key for ImmichFrame to talk to Immich.

        See
        <https://immichframe.online/docs/getting-started/configuration#api-key-permissions>
        for detials on the required permissions.
      '';
      persist = true;
    };
  };

  services.immichframe = {
    enable = true;
    port = 10510;
    settings = {
      General = {
        ShowClock = false;
        ImageZoom = false;
        ShowProgressBar = false;
        ShowPhotoDate = false;
        ShowImageDesc = false;
        ShowPeopleDesc = false;
        ShowAlbumName = false;
        ShowImageLocation = false;
        ImageFill = false;
      };

      Accounts = [
        {
          ImmichServerUrl = "http://immich.m";
          ApiKeyFile = config.clan.core.vars.generators.immichframe-api-key.files."api-key".path;
          Albums = [ "0ac6c0b6-39c8-4cf9-9793-3c5817eefdd2" ];
        }
      ];
    };
  };
}
