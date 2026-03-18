{
  flake',
  pkgs,
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    ;

  cfg = config.services.kodi-colusita.moonlight;

  # Very incomplete, lol.
  # https://github.com/torvalds/linux/blob/master/include/uapi/linux/input-event-codes.h
  keycodes = {
    KEY_RED = 398;
  };

  toggleUserService = pkgs.writeShellApplication {
    name = "toggle-user-service";
    runtimeInputs = [ pkgs.systemd ];
    text = ''
      if [ $# -ne 1 ]; then
        echo "Must provide exactly 1 service to toggle"
        exit 1
      fi

      service=$1

      if systemctl --user is-active --quiet "$service"; then
        echo "Stopping $service"
        systemctl --user --no-block stop "$service"
      else
        echo "Starting $service"
        systemctl --user --no-block start "$service"
      fi

      ${lib.getExe' pkgs.sox "play"} --no-show-progress ${../../nixos-modules/q/wav/owin31.wav}
    '';
  };
in

{
  options.services.kodi-colusita.moonlight = {
    enable = mkEnableOption "kodi-colusita";

    startOnKeycode = mkOption {
      type = lib.types.nullOr (lib.types.enum (lib.attrNames keycodes));
      default = null;
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = (cfg.startOnKeycode != null) -> (config.services.kodi-colusita.user != null);
        message = "startOnKeycode requires that `config.services.kodi-colusita.user` is enabled.";
      }
    ];

    services.kodi-colusita.extraAddons = [
      config.services.kodi-colusita.package.packages.joystick
      flake'.packages.kodiPackages.moonlight
    ];

    systemd.user.services.moonlight = {
      enable = true;
      partOf = [ "graphical-session.target" ];
      serviceConfig.ExecStart = lib.escapeShellArgs [
        (lib.getExe pkgs.moonlight-qt)
        "stream"
        "gurgi.ec"
        "Desktop" # So-called "app".
        "--resolution"
        "1920x1080"
        "--capture-system-keys"
        "always" # Ensure the windows key gets sent to the host.
      ];

      # Do not allow moonlight and kodi to run simultaneously. They fight for
      # being on top, and they also fight over the audio device. Instead,
      # ensure that when moonlight starts, kodi stops, and when moonlight stops
      # (for whatever reason), we start kodi back up.
      conflicts = [ "kodi.service" ];
      serviceConfig.ExecStopPost = "${lib.getExe' pkgs.systemd "systemctl"} --user start kodi.service";
    };

    services.actkbd = mkIf (cfg.startOnKeycode != null) {
      enable = true;
      bindings = [
        # Let the user start/stop moonlight with the remote control.
        {
          keys = [ keycodes.${cfg.startOnKeycode} ];
          events = [ "key" ];
          command = "systemd-run --user --machine ${config.services.kodi-colusita.user}@ ${lib.getExe toggleUserService} moonlight.service";
        }
      ];
    };
  };
}
