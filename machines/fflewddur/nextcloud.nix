{ config, pkgs, ... }:
let
  inherit (config.snow) services;
in
{
  services.data-mesher.settings.host.names = [ services.nextcloud.sld ];
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;
    hostName = services.nextcloud.fqdn;
    database.createLocally = true;
    config = {
      dbtype = "pgsql";
      adminpassFile = config.clan.core.vars.generators.nextcloud-admin.files."password".path;
    };

    # Workaround for 0-byte files that get created when using DAVx5 to upload files. See:
    # - https://github.com/nextcloud/server/issues/7995
    # - https://github.com/nextcloud/documentation/issues/9574
    nginx.enableFastcgiRequestBuffering = true;

    # According to
    # https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/config_sample_php_parameters.html#overwriteprotocol,
    # Nextcloud is supposed to auto-detect if we're using HTTPS, but it doesn't
    # seem to work. I haven't dug into why.
    settings.overwriteprotocol = "https";
  };

  # Force HTTPS.
  services.nginx.virtualHosts.${services.nextcloud.fqdn} = {
    enableACME = true;
    forceSSL = true;
  };

  clan.core.vars.generators.nextcloud-admin = {
    files."password" = { };
    runtimeInputs = with pkgs; [
      coreutils
      xkcdpass
    ];
    script = ''
      xkcdpass --numwords 4 --delimiter - | tr -d "\n" > $out/password
    '';
  };

  snow.backup.paths = [ config.services.nextcloud.home ];
}
