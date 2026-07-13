# This exists to test a regression in the bitwarden android app.
# When you're done with this, search the test of the repo for
# "TODO: remove once done bisecting bitwarden android."
# to clean everything else up.
{ config, ... }:
{
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
      LOG_LEVEL = "trace";
      EXTENDED_LOGGING = true;
    };
  };

  snow.services.vw-public.proxyPass = "http://[::1]:${toString config.services.vaultwarden.config.ROCKET_PORT}";
  snow.services.vw-overlay.proxyPass = "http://[::1]:${toString config.services.vaultwarden.config.ROCKET_PORT}";
}
