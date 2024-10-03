{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;

  cfg = config.services.kodi-colusita;

  settingsAddon = pkgs.kodiPackages.toKodiAddon (
    pkgs.stdenv.mkDerivation {
      name = "settings";
      src = ./settings;

      postBuild = ''
        substituteInPlace share/kodi/system/advancedsettings.xml \
          --replace-fail "@devicename@" ${config.networking.hostName}
      '';
      installPhase = "cp -r . $out";
    }
  );

  myKodi = pkgs.kodi.withPackages (kodiAddons: [
    settingsAddon
    kodiAddons.jellyfin
  ]);
in

{
  options.services.kodi-colusita = {
    enable = mkEnableOption "kodi-colusita";
    startOnBoot = mkOption {
      type = types.bool;
      description = "Whether to start kodi on boot";
      default = false;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ myKodi ];

    systemd.user.services = {
      "kodi" = {
        enable = cfg.startOnBoot;
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${myKodi}/bin/kodi";
        };
      };
    };

    # Needed for Kodi zeroconf to work.
    # Unfortunately, I think it doesn't really make sense to put this logic
    # into Nixpkgs because Nixpkgs doesn't have a mechanism for
    # enabling/disabling Kodi's Zeroconf feature (by creating an
    # advancedsettings.xml). We do that ourselves above in `settingsAddon`.
    # Reading through
    # <https://discourse.nixos.org/t/right-way-to-install-kodi-and-plugins/19181/35>,
    # I see that Home Manager *does* have this logic, but it also sounds like
    # there's some hope it'll end up in core nixpkgs someday.
    services.avahi.publish.enable = true;
    services.avahi.publish.userServices = true;
  };
}
