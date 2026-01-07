{
  config,
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

  # Enable MPD
  services.mpd = {
    enable = true;
    settings = {
      music_directory = "/home/${config.snow.user.name}/media/music";
      audio_output = [
        {
          type = "pipewire";
          name = "PipeWire Sound Server";
        }
      ];
    };
    startWhenNeeded = true; # `systemd` feature: only start MPD service upon connection to its socket.
  };
  # Workaround needed because mpd runs as system service, but
  # PipeWire runs as a user service.
  # See https://nixos.wiki/wiki/MPD#PipeWire_workaround.
  # Hopefully we could instead just run mpd as a user service? See
  # https://github.com/NixOS/nixpkgs/issues/41772#issuecomment-1225893858
  # for a glimmer of hope.
  services.mpd.user = config.snow.user.name;
  systemd.services.mpd.environment = {
    # https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/609
    XDG_RUNTIME_DIR = "/run/user/${toString config.snow.user.uid}";
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
    #### Beets
    beets
    abcde
    mp3val

    #### MPD
    ashuffle
    mpc
    mcg
  ];
}
