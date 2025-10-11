{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.snow.oama;
  oamaConfig = pkgs.writeTextFile {
    name = "config.yaml";
    text = lib.strings.toJSON {
      encryption.tag = "KEYRING";
      services.google = {
        client_id_cmd = "cat ${
          config.clan.core.vars.generators.google-oauth-client.files."client_id".path
        }";
        client_secret_cmd = "cat ${
          config.clan.core.vars.generators.google-oauth-client.files."client_secret".path
        }";
        auth_scope = lib.concatStringsSep " " [
          "https://mail.google.com/"
          "https://www.googleapis.com/auth/calendar"
        ];
      };
    };
  };
in
{
  options.snow.oama = {
    package = lib.mkOption {
      default = pkgs.symlinkJoin {
        inherit (pkgs.oama) name meta;
        paths = [ pkgs.oama ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/oama --add-flags "--config ${oamaConfig}"
        '';
      };
      readOnly = true;
    };
  };

  config = {
    clan.core.vars.generators.google-oauth-client = {
      prompts.client_id = {
        description = "Client id for a Google OAuth client. See https://github.com/pdobsan/oama for details.";
        persist = true;
      };
      files.client_id.owner = config.snow.user.name;

      prompts.client_secret = {
        description = "Client secret for a Google OAuth client. See https://github.com/pdobsan/oama for details.";
        persist = true;
      };
      files.client_secret.owner = config.snow.user.name;
    };

    ## Enable secret service api.
    # `oama` depends on the secret service api for storing OAuth credentials.
    services.gnome.gnome-keyring.enable = true;
    # This conflicts with ssh-agent, which is enabled elsewhere.
    services.gnome.gcr-ssh-agent.enable = false;
    # Workaround for <https://wiki.archlinux.org/title/GNOME/Keyring#Using_gnome-keyring-daemon_outside_desktop_environments_(KDE,_GNOME,_XFCE,_...)>
    services.xserver.updateDbusEnvironment = true;

    environment.systemPackages = [ cfg.package ];
  };
}
