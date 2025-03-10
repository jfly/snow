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

  myKodi = pkgs.symlinkJoin {
    name = "kodi";
    paths = [
      (cfg.package.withPackages (
        kodiAddons:
        [
          settingsAddon
          kodiAddons.jellyfin
        ]
        ++ cfg.extraAddons
      ))
    ];
    buildInputs = [ pkgs.makeWrapper ];
    # Adding `gdb` to the `PATH` allows Kodi's coredumps to include stack traces.
    postBuild = ''
      wrapProgram $out/bin/kodi --prefix PATH : ${lib.makeBinPath [ pkgs.gdb ]}
    '';
  };
in

{
  imports = [ ./moonlight.nix ];

  options.services.kodi-colusita = {
    enable = mkEnableOption "kodi-colusita";

    package = lib.mkPackageOption pkgs "kodi" { };

    startOnBoot = mkOption {
      type = types.bool;
      description = "Whether to start kodi on boot";
      default = false;
    };

    user = mkOption {
      type = types.nullOr types.str;
      description = ''
        The user to run Kodi under. Only relevant if
        {option}`services.kodi-colusita.startOnBoot` is enabled.
      '';
      default = if cfg.startOnBoot then "kodi" else null;
    };

    extraAddons = mkOption {
      type = types.listOf types.package;
      description = ''
        Additional Kodi addons to install.
      '';
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.startOnBoot -> config.services.xserver.enable;
        message = "startOnBoot requires that `config.services.xserver.enable` is enabled.";
      }
    ];

    environment.systemPackages = [ myKodi ];

    users.users.${cfg.user} = mkIf (cfg.user != null) {
      isNormalUser = true; # Kodi needs a home directory to store `~/.kodi/`.
      extraGroups = [
        # Needed to access `/dev/ttyACM0`, which is used by `libcec`. See
        # https://flameeyes.blog/2020/06/25/kodi-nuc-and-cec-adapters/ for details.
        "dialout"
      ];
    };

    services.displayManager.autoLogin = mkIf cfg.startOnBoot {
      enable = true;
      user = cfg.user;
    };

    systemd.user.services.kodi = {
      enable = cfg.startOnBoot;
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${myKodi}/bin/kodi";
        # Kodi segfaults periodically :cry:. Start it back up if it crashes.
        Restart = "on-failure";
        # Kodi often hangs when shutting down. I haven't been able to find
        # much of a discussion about this, but I have found how 2 other projects handle this:
        #
        # - `kodi-standalone-service` sends a `killall` to `kodi.bin`:
        #   https://github.com/graysky2/kodi-standalone-service/blob/v1.137/x86/init/kodi-x11.service#L14
        # - LibreElec: wraps Kodi with a script that does a `killall kodi.bin`:
        #   https://github.com/LibreELEC/LibreELEC.tv/blob/e7837d8fcbd6e884fad69472b55ff1f993b9c370/packages/mediacenter/kodi/scripts/kodi.sh#L31-L35
        #   They configure systemd to send that wrapper script a `SIGTERM` on
        #   exit:
        #   https://github.com/LibreELEC/LibreELEC.tv/blob/12.0.1/packages/mediacenter/kodi/system.d/kodi.service#L13
        #
        # Thoughts for improvement:
        #  - Has anyone asked about this upstream? Seems like kodi itself
        #    should (be changed to) be able to exit cleanly.
        #  - If that doesn't happen, this should live in a systemd unit definition in
        #    `nixpkgs`. It sounds like `@aanderse` might be open to investing in
        #    that:
        #    https://discourse.nixos.org/t/right-way-to-install-kodi-and-plugins/19181/35.
        TimeoutStopSec = "10s";
      };
    };

    networking.firewall.allowedTCPPorts = [
      8080 # Web server
      9090 # JSON/RPC
    ];
    networking.firewall.allowedUDPPorts = [
      9777 # Event Server
    ];

    # Needed for Kodi zeroconf to work.
    # Unfortunately, I think it doesn't really make sense to put this logic
    # into `nixpkgs` because `nixpkgs` doesn't have a mechanism for
    # enabling/disabling Kodi's Zeroconf feature (by creating an
    # `advancedsettings.xml`). We do that ourselves above in `settingsAddon`.
    # Reading through
    # <https://discourse.nixos.org/t/right-way-to-install-kodi-and-plugins/19181/35>,
    # I see that Home Manager *does* have this logic, but it also sounds like
    # there's some hope it'll end up in core `nixpkgs` someday.
    services.avahi.enable = true;
    services.avahi.publish.enable = true;
    services.avahi.publish.userServices = true;
  };
}
