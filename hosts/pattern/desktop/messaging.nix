{ lib, pkgs, ... }:

{
  systemd.user.services = {
    "signal" = {
      enable = true;

      # See `./desktop/xmonad-startup-workaround.nix` for why we can't use
      # `graphical-session.target`.
      # wantedBy = [ "graphical-session.target" ];
      # partOf = [ "graphical-session.target" ];
      wantedBy = [ "xmonad.target" ];
      partOf = [ "xmonad.target" ];

      serviceConfig = {
        ExecStart = lib.getExe pkgs.signal-desktop-source;
      };
    };
  };
}
