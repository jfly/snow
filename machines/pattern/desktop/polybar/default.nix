{ pkgs, ... }:

let
  polybar = pkgs.polybar.override {
    mpdSupport = true;
  };
in
{
  systemd.user.services.polybar = {
    enable = true;
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${polybar}/bin/polybar --config=${./polybar-config.ini}";
    };
  };
}
