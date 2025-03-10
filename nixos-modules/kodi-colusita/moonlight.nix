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
  inherit (builtins)
    concatStringsSep
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
      serviceConfig = {
        ExecStart = concatStringsSep " " [
          "${pkgs.moonlight-qt}/bin/moonlight"
          "stream"
          "gurgi.ec"
          "Desktop" # So-called "app".
          "--resolution"
          "1920x1080"
          "--capture-system-keys"
          "always" # Ensure the windows key gets sent to the host.
        ];
      };
    };
  };
}
