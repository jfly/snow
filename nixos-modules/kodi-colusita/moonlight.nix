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
    ;

  cfg = config.services.kodi-colusita;
in

{
  options.services.kodi-colusita.moonlight = {
    enable = mkEnableOption "kodi-colusita";
  };

  config = mkIf cfg.moonlight.enable {
    services.kodi-colusita.extraAddons = [
      cfg.package.packages.joystick
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
  };
}
