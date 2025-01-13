{ pkgs, ... }:

let
  polybar = pkgs.polybar.override {
    mpdSupport = true;
  };
  polybarConfig = pkgs.substituteAll {
    src = ./polybar-config.ini;
  };
in
{
  systemd.user.services.polybar = {
    enable = true;
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${polybar}/bin/polybar --config=${polybarConfig}";
    };
  };
}
