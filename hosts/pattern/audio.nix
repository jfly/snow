{
  flake',
  lib,
  pkgs,
  ...
}:

let
  mcg = flake'.packages.cover-grid;
in
{
  # Enable sound with pipewire.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  systemd.user.services = {
    "mcg" = {
      enable = true;

      # See `./desktop/xmonad-startup-workaround.nix` for why we can't use
      # `graphical-session.target`.
      # wantedBy = [ "graphical-session.target" ];
      # partOf = [ "graphical-session.target" ];
      wantedBy = [ "xmonad.target" ];
      partOf = [ "xmonad.target" ];

      serviceConfig = {
        ExecStart = lib.getExe mcg;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    mpc-cli
    mcg
    beets
    abcde
    mp3val
    #### MPD
    ashuffle
  ];
}
