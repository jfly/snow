{ config, lib, pkgs, modulesPath, ... }:

let
  username = "jeremy";
  alacritty = (pkgs.callPackage ../dotfiles/my-nix/with-alacritty { });
  polybar = pkgs.polybar.override {
    mpdSupport = true;
  };
  polybarConfig = ../dotfiles/homies/config/polybar/config.ini;
  space2meta = pkgs.callPackage ./space2meta.nix { };
  dunst = pkgs.callPackage ../dotfiles/my-nix/dunst { };
  jscrot = pkgs.callPackage ../shared/jscrot {};
in
{
  services.xserver = {
    enable = true;
    autorun = true;
    displayManager = {
      defaultSession = "none+xmonad";
      autoLogin.enable = true;
      autoLogin.user = username;
    };
    windowManager.xmonad = {
      enable = true;
      config = ../dotfiles/my-nix/xmonad/xmonad.hs;
      extraPackages = s: [ s.xmonad-contrib ];
    };
    autoRepeatDelay = 300;
    autoRepeatInterval = 30;
  };

  # Enable touchpad.
  services.xserver.libinput.enable = true;

  # TODO: figure out how to enable native GPU, I know this machine has one!
  services.xserver.videoDrivers = [ "modesetting" ];
  services.xserver.useGlamor = true;

  programs.nm-applet.enable = true;

  systemd.user.services = {
    # TODO: run autoperipherals on boot + whenever hardware changes, load ~/.Xresources
    # TODO: enable numlock on boot
    # TODO: add blueman-applet
    # TODO: add xsettingsd
    # TODO: add gnome-keyring
    # TODO: add mcg
    # TODO: add volnoti
    # TODO: set up ssh agent

    "polybar" = {
      enable = true;
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${polybar}/bin/polybar --config=${polybarConfig}";
      };
    };
    "pasystray" = {
      enable = true;
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      path = [ pkgs.pavucontrol ];
      serviceConfig = {
        ExecStart = "${pkgs.pasystray}/bin/pasystray";
      };
    };
    "dunst" = {
      enable = true;
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${dunst}/bin/dunst";
      };
    };
  };

  services.interception-tools = {
    enable = true;
    udevmonConfig = ''
      - JOB: ${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${pkgs.interception-tools-plugins.caps2esc}/bin/caps2esc -m 1 | ${space2meta}/bin/space2meta | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE
        DEVICE:
          EVENTS:
            EV_KEY: [KEY_CAPSLOCK, KEY_ESC, KEY_SPACE]
    '';
  };

  # Lock the screen on suspend. Trick copied from
  # https://wiki.archlinux.org/title/Slock#Lock_on_suspend.
  programs.slock.enable = true;
  systemd.services = {
    "slock" = {
      enable = true;
      description = "Lock X session using slock for user";
      before = [ "sleep.target" ];
      wantedBy = [ "sleep.target" ];
      environment.DISPLAY = ":0";
      serviceConfig = {
        User = username;
        ExecStartPre = "${pkgs.xorg.xset}/bin/xset dpms force suspend";
        ExecStart = "/run/wrappers/bin/slock"; # use the setuid slock wrapper
      };
    };
  };

  nixpkgs.config.chromium.commandLineArgs = builtins.concatStringsSep " " [
    "--oauth2-client-id=77185425430.apps.googleusercontent.com"
    "--oauth2-client-secret=OTJgUOQcT7lO7GsGZq2G4IlT"
  ];

  environment.systemPackages = with pkgs; [
    (pkgs.symlinkJoin {
      name = "chromium";
      paths = [ chromium ];
      buildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/chromium \
          --set GOOGLE_DEFAULT_CLIENT_ID 77185425430.apps.googleusercontent.com \
          --set GOOGLE_DEFAULT_CLIENT_SECRET OTJgUOQcT7lO7GsGZq2G4IlT
      '';
    })
    qutebrowser
    gnome.eog
    feh
    (pkgs.callPackage (import ../sources.nix).parsec-gaming { })
    mpv
    yt-dlp
    evince

    ### Debugging
    arandr
    xorg.xkill
    xorg.xev

    # TODO: consolidate with xmonad
    alacritty
    jscrot
    xdotool
    dmenu
    xcwd
  ];
}
