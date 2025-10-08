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

  clan.core.vars.generators.hello-at-ramfly-app-password = {
    prompts.password = {
      description = "Fastmail app password for hello@ramfly.net (https://app.fastmail.com/settings/security/apps)";
      persist = true;
    };
    files.password.owner = config.snow.user.name;
  };

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
          config.clan.core.vars.generators.hello-at-ramfly-app-password.files."password".path
        }";
        host = "smtp.fastmail.com";
      };

    extraConfig = ''
      account default : jfly-gmail
    '';
  };

  clan.core.vars.generators.fastmail-jfly-api-token = {
    prompts.token = {
      description = "Fastmail api token for jfly (https://app.fastmail.com/settings/security/tokens)";
      persist = true;
    };
    files.token.owner = config.snow.user.name;
  };
  clan.core.vars.generators.fastmail-ramfly-api-token = {
    prompts.token = {
      description = "Fastmail api token for ramfly (https://app.fastmail.com/settings/security/tokens)";
      persist = true;
    };
    files.token.owner = config.snow.user.name;
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
