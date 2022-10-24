{ config, lib, pkgs, modulesPath, ... }:

let
  alacritty = (pkgs.callPackage ../shared/my-nix/with-alacritty { });
  polybar = pkgs.polybar.override {
    mpdSupport = true;
  };
  polybarConfig = ../shared/polybar/config.ini;
  space2meta = pkgs.callPackage ./space2meta.nix { };
  dunst = pkgs.callPackage ../shared/my-nix/dunst { };
  xmonad = pkgs.callPackage ../shared/xmonad { };
  autoperipherals = pkgs.callPackage ../shared/autoperipherals { };
  # TODO: conslidate with pattern/laptop.nix
  restart-user-service = pkgs.writeShellScript "restart-user-service" ''
    user=$1
    service=$2
    uid=$(id -u $user)
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus"
    ${pkgs.sudo}/bin/sudo -u "$1" --preserve-env=DBUS_SESSION_BUS_ADDRESS ${pkgs.systemd}/bin/systemctl --user restart "$service"
  '';
  noto-fonts-emoji-monochrome = pkgs.callPackage ../shared/noto-fonts-emoji-monochrome { };
in
{
  services.xserver = {
    enable = true;
    autorun = true;
    displayManager = {
      defaultSession = "none+xmonad";
      autoLogin.enable = true;
      autoLogin.user = config.snow.user.name;
    };
    windowManager = {
      session = [{
        name = "xmonad";
        start = ''
          # Xmonad doesn't set a cursor.
          ${pkgs.xorg.xsetroot}/bin/xsetroot -cursor_name left_ptr

          systemd-cat -t xmonad -- ${xmonad}/bin/xmonad &
          waitPID=$!
        '';
      }];
    };
    # Set up a pretty fast keyrepeat.
    autoRepeatDelay = 300;
    autoRepeatInterval = 30;
  };

  # Enable dconf. I'm a bit torn about this: some applications like to
  # save settings here, which means if we reprovision, we lose those
  # settings.
  programs.dconf.enable = true;

  # Enable touchpad.
  services.xserver.libinput.enable = true;

  hardware.opengl.enable = true;

  programs.nm-applet.enable = true;

  services.xserver.displayManager.importedVariables = [
    "PATH"
    "BROWSER"
  ];

  systemd.user.services = {
    "xsettingsd" = {
      enable = true;
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.xsettingsd}/bin/xsettingsd";
      };
    };
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
      # stage2ServiceConfig in nixos/lib/systemd-lib.nix really wants to give
      # us a default PATH. However, dunst currently uses xdg-open to fire up a
      # browser, and *that* needs a PATH with whatever default browser we've
      # got set up. So, it's better to use systemctl's "user environment block"
      # (populated by xsessionWrapper when it calls `systemctl
      # import-environment`), because that'll have the right PATH and BROWSER,
      # but to inherit that PATH, we have to make sure we don't specify a PATH
      # whatsoever.
      path = lib.mkForce [ ];
      serviceConfig = {
        ExecStart = "${dunst}/bin/dunst";
      };
    };
    "numlock-on" = {
      enable = true;
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.numlockx}/bin/numlockx on";
      };
    };
  };

  # Run autoperipherals on boot + whenever hardware changes
  services.xserver.displayManager.setupCommands = ''
    ${autoperipherals}/bin/autoperipherals
  '';
  systemd.user.services = {
    "autoperipherals" = {
      enable = true;
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${autoperipherals}/bin/autoperipherals";
      };
    };
  };
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", ACTION=="change", RUN+="${restart-user-service} ${config.snow.user.name} autoperipherals"
  '';

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  # The blueman-applet service is defined in a way such that it is
  # triggered by dbus. I'd rather just have it start up, so here we make
  # some tweaks.
  systemd.user.services."blueman-applet" = {
    enable = true;
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
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
        User = config.snow.user.name;
        ExecStartPre = "${pkgs.xorg.xset}/bin/xset dpms force suspend";
        ExecStart = "/run/wrappers/bin/slock"; # use the setuid slock wrapper
      };
    };
  };

  ###
  ### Fonts!
  ###
  fonts =
    {
      fontDir.enable = true;
      # Disable the default fonts, things are more predictable that way.
      enableDefaultFonts = false;
      fonts = with pkgs; [
        (nerdfonts.override {
          fonts = [
            "UbuntuMono" # my preferred monospace font
          ];
        })
        noto-fonts-emoji-monochrome
        # I can't read any of this, but it sure looks nicer than boxes :p
        noto-fonts-cjk-serif
      ];
      fontconfig = {
        defaultFonts = {
          monospace = [ "UbuntuMono Nerd Font Mono" ];
        };
      };
    };
  ##########

  ### Java hacks
  environment.variables = {
    # Enable antialiasing. See: https://nixos.wiki/wiki/Java#Better_font_rendering
    _JAVA_OPTIONS = "-Dawt.useSystemAAFontSettings=lcd";
    # Hint to Java that xmonad is a "non-reparenting" window manager:
    # https://wiki.archlinux.org/title/Java#Gray_window,_applications_not_resizing_with_WM,_menus_immediately_closing
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };

  nixpkgs.config.chromium.commandLineArgs = builtins.concatStringsSep " " [
    "--enable-features=VaapiVideoEncoder,VaapiVideoDecoder,CanvasOopRasterization"
    "--disable-features=UseChromeOSDirectVideoDecoder"
    "--enable-gpu-rasterization"
    "--enable-zero-copy"
  ];

  environment.systemPackages = with pkgs; [
    ### Browsers
    qutebrowser
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

    ### Image viewers
    gnome.eog

    ### Movie players
    mpv
    yt-dlp
    subdl

    ### Media editing (images, audio, video)
    gimp
    inkscape
    avidemux
    audacity

    ### PDF
    evince

    ### Remote desktop
    (pkgs.callPackage (import ../sources.nix).parsec-gaming { })
    freerdp

    ### Compression/archives
    unzip

    ### Debugging
    arandr
    xorg.xkill
    xorg.xev
    libva-utils
    glxinfo
    pciutils
    gucharmap # view fonts

    # TODO: consolidate with xmonad
    alacritty
    (pkgs.callPackage ../shared/colorscheme { })
    xdotool
    (pkgs.symlinkJoin {
      name = "dmenu";
      paths = [ dmenu ];
      buildInputs = [ makeWrapper ];
      postBuild = ''
        for prog in dmenu dmenu_run; do
          wrapProgram $out/bin/$prog \
            --add-flags "-fn Monospace-15"
        done
      '';
    })
    xcwd
  ];
}
