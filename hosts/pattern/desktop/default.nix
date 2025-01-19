{
  flake,
  inputs',
  flake',
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    genAttrs
    ;

  inherit (builtins)
    filter
    ;

  inherit (flake'.packages)
    autoperipherals
    desk-speakers
    jbright
    jvol
    xmonad
    ;

  with-alacritty = inputs'.with-alacritty.packages.default.override {
    alacritty = pkgs.alacritty.overrideAttrs (oldAttrs: {
      patches = (if oldAttrs ? patches then oldAttrs.patches else [ ]) ++ [
        # Fixes an annoying bug in alacritty with Kitty keys. See:
        # - https://github.com/alacritty/alacritty/issues/8385
        # - https://github.com/neovim/neovim/issues/31806
        (pkgs.fetchpatch {
          name = "Fix report of Enter/Tab/Backspace in kitty keyboard";
          url = "https://github.com/alacritty/alacritty/commit/7bda13b8aa59ed7bc3efe6d5b0bdb09b8e75f8a3.patch";
          hash = "sha256-HoE8GDAOqoLbaBgH7tM8HhKZ0EAvCY2fmWS3IHp24Pw=";
          excludes = [ "CHANGELOG.md" ];
        })
      ];
    });
  };

  dmenu = pkgs.symlinkJoin {
    name = "dmenu";
    paths = [ pkgs.dmenu ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for prog in dmenu dmenu_run; do
        wrapProgram $out/bin/$prog \
          --add-flags "-fn Monospace-15"
      done
    '';
  };
in
{
  imports = [
    ./kodi.nix
    ./xmonad-startup-workaround.nix
    ./polybar
    ./messaging.nix
    flake.nixosModules.colorscheme
  ];

  services.displayManager = {
    defaultSession = "none+xmonad";
    autoLogin.enable = true;
    autoLogin.user = config.snow.user.name;
  };
  services.xserver = {
    enable = true;
    autorun = true;
    windowManager = {
      session = [
        {
          name = "xmonad";
          start = ''
            # Xmonad doesn't set a cursor.
            ${pkgs.xorg.xsetroot}/bin/xsetroot -cursor_name left_ptr

            systemd-cat -t xmonad -- ${xmonad}/bin/xmonad &
            waitPID=$!
          '';
        }
      ];
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
  services.libinput.enable = true;

  hardware.graphics.enable = true;

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
      # `stage2ServiceConfig` in `nixos/lib/systemd-lib.nix` really wants to give
      # us a default `PATH`. However, dunst currently uses `xdg-open` to fire up a
      # browser, and *that* needs a PATH with whatever default browser we've
      # got set up. So, it's better to use systemctl's "user environment block"
      # (populated by xsessionWrapper when it calls `systemctl
      # import-environment`), because that'll have the right PATH and BROWSER,
      # but to inherit that PATH, we have to make sure we don't specify a PATH
      # whatsoever.
      path = lib.mkForce [ ];
      serviceConfig = {
        ExecStart = "${flake'.packages.dunst}/bin/dunst";
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
  systemd.user.services = {
    "autoperipherals" = {
      enable = true;
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${autoperipherals}/bin/autoperipherals sync";
      };
    };
  };
  # TODO: consolidate with `pattern/laptop.nix`.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", ACTION=="change", RUN+="${lib.getExe pkgs.sudo} systemctl --machine ${config.snow.user.name}@ --user restart autoperipherals.service"
  '';
  # These targets are activated by autoperipherals itself. Other units may
  # depend on them (for example, imagine a service that you only want running
  # when you're at your desk).
  systemd.user.targets =
    let
      locations = [
        "garageman"
        "projector"
        "mobile"
      ];
      targetNames = map (name: "location-${name}") locations;
    in
    genAttrs targetNames (
      target:
      let
        otherTargets = filter (name: name != target) targetNames;
      in
      {
        conflicts = map (name: "${name}.target") otherTargets;
      }
    );

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

  services.interception-tools =
    let
      mux = "${pkgs.interception-tools}/bin/mux";
      intercept = "${pkgs.interception-tools}/bin/intercept";
      uinput = "${pkgs.interception-tools}/bin/uinput";
      caps2esc = "${pkgs.interception-tools-plugins.caps2esc}/bin/caps2esc";
      space2meta = "${flake'.packages.space2meta}/bin/space2meta";
    in
    # TODO: figure out key drop issues
    # space2meta-speedcubing = "${flake'.packages.space2meta-speedcubing}/bin/space2meta";
    {
      enable = true;
      # Note: stringified key names are found here: https://github.com/torvalds/linux/blob/master/include/uapi/linux/input-event-codes.h
      udevmonConfig = ''
        - CMD: ${mux} -c caps2esc

        # The `-d` passed to uinput creates a virtual keyboard on the fly that looks
        # like my laptop's keyboard. This is arguably kind of weird as these
        # events may have originated from a completely different type of
        # keyboard. (This is the "living dangerously" documentation from
        # https://gitlab.com/interception/linux/plugins/dual-function-keys#multiple-devices)
        # Note that things get even more complicated if you're interested in
        # "grabbing" the mouse and generating synthetic mouse events too.
        # Fortunately, we're not doing that, but this is useful reading
        # regardless:
        #   - https://gitlab.com/interception/linux/plugins/dual-function-keys/-/issues/31#note_725827382
        #   - https://gitlab.com/interception/linux/tools#hybrid-device-configurations
        - JOB: ${mux} -i caps2esc | ${caps2esc} -m 1 | ${space2meta} | ${uinput} -d /dev/input/by-path/platform-i8042-serio-0-event-kbd

        # Match devices that look like a mouse. Copied from
        # https://gitlab.com/interception/linux/plugins/dual-function-keys#multiple-devices
        # Note: this must go before the keyboard job, as my mouse bizarrely
        # (apparently this isn't so uncommon :() *does* have a bunch of keys
        # that make it look like a keyboard.
        - JOB: ${intercept} $DEVNODE | ${mux} -o caps2esc
          DEVICE:
            EVENTS:
              EV_REL: [REL_WHEEL]
              EV_KEY: [BTN_LEFT]

        # Match devices that look like a keyboard.
        - JOB: ${intercept} -g $DEVNODE | ${mux} -o caps2esc
          DEVICE:
            EVENTS:
              EV_KEY: [KEY_CAPSLOCK]
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
        ExecStart = "/run/wrappers/bin/slock"; # Use the setuid slock wrapper.
      };
    };
  };

  ###
  ### Fonts!
  ###
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      nerd-fonts.ubuntu-mono # My preferred monospace font.
      noto-fonts-monochrome-emoji # We use this in `polybar` to keep everything nice and black and white.
      flake'.packages.pica-font
      flake'.packages.dk-majolica-font
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
    eog

    ### Movie players
    mpv
    yt-dlp
    subdl

    ### Media editing (images, audio, video)
    gimp
    (inkscape-with-extensions.override { inkscapeExtensions = [ inkscape-extensions.silhouette ]; })
    avidemux
    audacity

    ### Ebooks/audiobooks
    (pkgs.symlinkJoin {
      name = "calibre";
      paths = [ pkgs.calibre ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/calibre \
          --add-flags "--with-library ~/sync/jfly/books/calibre"
      '';
    })
    audible-cli
    flake'.packages.snowcrypt
    flake'.packages.odmpy

    ### PDF
    evince

    ### Remote desktop
    moonlight-qt
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
    gucharmap # View fonts.
    usbutils # Provides `lsusb`.

    ### Misc desktop utils
    autoperipherals
    desk-speakers
    jbright
    jvol
    with-alacritty
    xclip
    xcwd
    xdotool
    xmonad
    dmenu
    gscan2pdf

    ### WiFi
    flake'.packages.ap

    ### VPN
    flake'.packages.snowvpn
  ];
}
