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
  volnoti = pkgs.callPackage ../shared/volnoti { };
  xmonad = pkgs.callPackage ../shared/xmonad { };
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
    windowManager = {
      session = [{
        name = "xmonad";
        start = ''
          systemd-cat -t xmonad -- ${xmonad}/bin/xmonad &
          waitPID=$!
        '';
      }];
    };
    autoRepeatDelay = 300;
    autoRepeatInterval = 30;
  };

  # Enable touchpad.
  services.xserver.libinput.enable = true;

  # This enables the intel gpu, but not the builtin NVIDIA card. See
  # https://wiki.archlinux.org/title/System76_Oryx_Pro#Graphics for more
  # information.
  # TODO: figure this out, it could be pretty cool =)
  services.xserver.videoDrivers = [ "modesetting" ];
  services.xserver.useGlamor = true;
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  programs.nm-applet.enable = true;

  # TODO: set up fonts

  systemd.user.services = {
    # TODO: run autoperipherals on boot + whenever hardware changes, load ~/.Xresources
    # TODO: enable numlock on boot
    # TODO: add blueman-applet
    # TODO: add xsettingsd
    # TODO: add gnome-keyring
    # TODO: add mcg

    "polybar" = {
      enable = true;
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${polybar}/bin/polybar --config=${polybarConfig}";
      };
    };
    "volnoti" = {
      enable = true;
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${volnoti}/bin/volnoti --no-daemon --timeout 1";
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

  # Set up ssh agent
  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
    extraConfig = ''
      AddKeysToAgent yes
    '';
  };
  environment.variables.SSH_ASKPASS_REQUIRE = "prefer";

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
    "--enable-features=VaapiVideoDecoder"
    "--disable-features=UseChromeOSDirectVideoDecoder"
    "--enable-gpu-rasterization"
    "--enable-zero-copy"
  ];

  environment.systemPackages = with pkgs; [
    (pkgs.symlinkJoin {
      name = "chromium";
      paths = [ chromium ];
      buildInputs = [ makeWrapper ];
      # Adding these as command line flags doesn't seem to work. Perhaps
      # because we don't have this patch?
      # https://github.com/archlinux/svntogit-packages/blob/2aa76e8dfdd647d1ca0fe1d8780459660407bad2/chromium/trunk/use-oauth2-client-switches-as-default.patch
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
    libva-utils
    glxinfo

    # TODO: consolidate with xmonad
    alacritty
    xdotool
    dmenu
    xcwd
  ];
}
