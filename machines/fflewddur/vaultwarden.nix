{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.snow) services;
in
{
  clan.core.vars.generators.vaultwarden-subpath = {
    prompts."subpath" = {
      description = ''
        We host Vaultwarden under a secret subpath as a form of defense in
        depth. See
        https://github.com/dani-garcia/vaultwarden/wiki/Hardening-Guide#hiding-under-a-subdir
      '';
      type = "hidden";
      persist = true;
    };
  };

  services.vaultwarden = {
    enable = true;

    backupDir = "/var/backup/vaultwarden";

    config = {
      # These are the defaults
      # <https://github.com/NixOS/nixpkgs/blob/20075955deac2583bb12f07151c2df830ef346b4/nixos/modules/services/security/vaultwarden/default.nix#L110-L111>,
      # but must be specified explicitly because by setting any config value we completely clobber the defaults.
      # I wonder if this would be better if this module was ported to use RFC
      # 42 style freeform options.
      ROCKET_ADDRESS = "::1"; # default to localhost
      ROCKET_PORT = 8222;

      # https://github.com/dani-garcia/vaultwarden/wiki/Hardening-Guide#disable-registration-and-optionally-invitations
      SIGNUPS_ALLOWED = false;
      INVITATIONS_ALLOWED = false;
      # https://github.com/dani-garcia/vaultwarden/wiki/Hardening-Guide#disable-password-hint-display
      SHOW_PASSWORD_HINT = false;
      # https://github.com/dani-garcia/vaultwarden/wiki/Logging
      # LOG_LEVEL = trace;
      # EXTENDED_LOGGING = true;
    };
  };

  systemd.services.vaultwarden.serviceConfig = {
    LoadCredential = [
      "subpath:${config.clan.core.vars.generators.vaultwarden-subpath.files."subpath".path}"
    ];
    ExecStart = lib.mkForce (
      pkgs.writeShellScript "post-fetch" ''
        export DOMAIN=${services.vaultwarden.base_url}/$(< "$CREDENTIALS_DIRECTORY/subpath")
        exec ${lib.getExe pkgs.vaultwarden}
      ''
    );
  };

  services.data-mesher.settings.host.names = [ services.vaultwarden.sld ];
  services.nginx.virtualHosts.${services.vaultwarden.fqdn} = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://[::1]:${toString config.services.vaultwarden.config.ROCKET_PORT}";
    };
  };

  snow.backup.paths = [ config.services.vaultwarden.backupDir ];
}
