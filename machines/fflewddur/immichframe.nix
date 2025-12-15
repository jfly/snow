{ config, ... }:
{
  snow.services.immichframe.proxyPass = "http://localhost:${toString config.services.immichframe.port}";

  clan.core.vars.generators.immichframe-api-key = {
    prompts."api-key" = {
      description = ''
        API key for ImmichFrame to talk to Immich.

        See
        <https://immichframe.online/docs/getting-started/configuration#api-key-permissions>
        for details on the required permissions.
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
