{
  flake',
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

  systemd.user.targets = {
    # This xmonad target just exists as a workaround for
    # https://github.com/xmonad/xmonad/issues/422.
    # See shared/xmonad/xmonad.hs for where this target gets triggered.
    "xmonad" = {
      enable = true;
      partOf = [ "graphical-session.target" ];
    };
  };
  systemd.user.services = {
    "mcg" = {
      enable = true;

      # We can't use graphical-session because of
      # https://github.com/xmonad/xmonad/issues/422.
      # wantedBy = [ "graphical-session.target" ];
      # partOf = [ "graphical-session.target" ];
      wantedBy = [ "xmonad.target" ];
      partOf = [ "xmonad.target" ];

      serviceConfig = {
        ExecStart = "${mcg}/bin/mcg";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    mpc-cli
    mcg
    beets
    abcde
    mp3val
    # TODO: follow up after a while and see if we need these (plugins?) somehow.
    # AddPackage python-pyacoustid # Bindings for Chromaprint acoustic fingerprinting and the Acoustid API
    # AddPackage python-eyed3 # A Python module and program for processing information about mp3 files
    #### MPD
    ashuffle
  ];
}
