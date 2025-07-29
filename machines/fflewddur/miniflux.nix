{ config, ... }:
let
  inherit (config.snow) services;
in
{
  services.miniflux = {
    enable = true;
    config = {
      CREATE_ADMIN = 0;

      # Enable SSO.
      # https://miniflux.app/docs/howto.html#openid-connect
      OAUTH2_PROVIDER = "oidc";
      OAUTH2_CLIENT_ID = services.miniflux.oauth2.clientId;
      OAUTH2_REDIRECT_URL = services.miniflux.urls.oauth2Callback;
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = services.kanidm.urls.oauth2OidcIssuer {
        clientId = services.miniflux.oauth2.clientId;
      };
      OAUTH2_USER_CREATION = 1;

      # Fetch video durations from YouTube. This seems to be safe to
      # set, and is disabled by default out of FUD about YouTube api
      # rate limits. See
      # https://github.com/miniflux/v2/pull/994#issuecomment-780691681
      # for details.
      FETCH_YOUTUBE_WATCH_TIME = 1;
    };

    oauth2ClientSecretFile = services.miniflux.oauth2.clientSecretPath;
  };

  services.postgresqlBackup = {
    enable = true;
    databases = [ "miniflux" ];
  };
  snow.backup.paths = [ config.services.postgresqlBackup.location ];

  services.data-mesher.settings.host.names = [ services.miniflux.sld ];
  services.nginx.virtualHosts.${services.miniflux.fqdn} = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://localhost:8080";
    };
  };
}
