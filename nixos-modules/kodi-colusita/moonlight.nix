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

    systemd.user.services.cecdaemon =
      let
        cecConf = {
          tv.name = "Gurgi";
          keymap = { };
          # This lets the user stop moonlight with the remote control. Note the
          # chosen button is exactly the same as the one in the moonlight kodi
          # package (see its share/kodi/system/keymaps/z_moonlight.xml).
          cmd_stop_moonlight = {
            key = 114; # Red button.
            holdtime = 0;
            command = pkgs.writeShellScript "stop-moonlight" ''
              ${pkgs.sox}/bin/play -q ${../../nixos-modules/q/wav/owin31.wav} &
              ${lib.getExe' pkgs.systemd "systemctl"} --user stop moonlight.service
            '';
          };
        };

        settingsFormat = pkgs.formats.ini { };
        configFile = settingsFormat.generate "cec.conf" cecConf;
      in
      {
        enable = true;
        wantedBy = [ "moonlight.service" ]; # Start when moonlight starts.
        partOf = [ "moonlight.service" ]; # Stop when moonlight stops.
        serviceConfig.ExecStart = "${lib.getExe pkgs.cecdaemon} --config=${configFile}";
      };
  };
}
