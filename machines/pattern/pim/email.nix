{
  lib,
  config,
  pkgs,
  flake',
  ...
}:
{
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
        passwordeval = "${lib.getExe config.snow.oama.package} access ${email}";
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
