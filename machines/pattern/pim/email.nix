{
  lib,
  config,
  pkgs,
  flake',
  ...
}:
let
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
      };
    };
  };
  myOama = pkgs.symlinkJoin {
    inherit (pkgs.oama) name meta;
    paths = [ pkgs.oama ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/oama --add-flags "--config ${oamaConfig}"
    '';
  };
in
{
  ## Enable secret service api.
  # `oama` depends on the secret service api for storing OAuth credentials.
  services.gnome.gnome-keyring.enable = true;
  # This conflicts with ssh-agent, which is enabled elsewhere.
  services.gnome.gcr-ssh-agent.enable = false;
  # Workaround for <https://wiki.archlinux.org/title/GNOME/Keyring#Using_gnome-keyring-daemon_outside_desktop_environments_(KDE,_GNOME,_XFCE,_...)>
  services.xserver.updateDbusEnvironment = true;

  programs.msmtp = {
    enable = true;
    defaults = {
      tls = true;
      tls_starttls = "off";
      port = 465;
      auth = "on";
    };
    accounts.jfly-gmail =
      let
        email = "jeremyfleischman@gmail.com";
      in
      {
        from = email;
        user = email;
        auth = "oauthbearer";
        passwordeval = "oama access ${email}";
        host = "smtp.gmail.com";
      };

    accounts.ramfly =
      let
        email = "hello@ramfly.net";
      in
      {
        from = email;
        user = email;
        passwordeval = "cat ${
          config.clan.core.vars.generators.fastmail-ramfly-app-password.files."password".path
        }";
        host = "smtp.fastmail.com";
      };

    extraConfig = ''
      account default : jfly-gmail
    '';
  };

  environment.systemPackages = [
    myOama
    flake'.packages.aerc

    # These are used by aerc. See `source-cred-cmd` in `accounts.conf`.
    (pkgs.writeShellApplication {
      name = "fastmail-api-token-jfly";
      text = ''
        cat ${config.clan.core.vars.generators.fastmail-jfly-api-token.files."token".path}
      '';
    })
    (pkgs.writeShellApplication {
      name = "fastmail-api-token-ramfly";
      text = ''
        cat ${config.clan.core.vars.generators.fastmail-ramfly-api-token.files."token".path}
      '';
    })
  ];
}
