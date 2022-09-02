{ config, lib, pkgs, modulesPath, ... }:

let
  alacritty = (pkgs.callPackage ../dotfiles/my-nix/with-alacritty { });
  polybar = pkgs.polybar.override {
    mpdSupport = true;
  };
  polybarConfig = ../dotfiles/homies/config/polybar/config.ini;
  space2meta = pkgs.callPackage ./space2meta.nix { };
  dunst = pkgs.callPackage ../dotfiles/my-nix/dunst { };
  xmonad = pkgs.callPackage ../shared/xmonad { };
  autoperipherals = pkgs.callPackage ../shared/autoperipherals { };
  restart-user-service = pkgs.writeShellScript "restart-user-service" ''
    user=$1
    service=$2
    uid=$(id -u $user)
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus"
    ${pkgs.sudo}/bin/sudo -u "$1" --preserve-env=DBUS_SESSION_BUS_ADDRESS ${pkgs.systemd}/bin/systemctl --user restart "$service"
  '';
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

  # This is a System76 Gazelle 16 with an NVIDIA RTX 3060, which means we have
  # support for 1x DisplayPort 1.4 over USB-C:
  # https://tech-docs.system76.com/models/gaze16/README.html
  # This also means we have 2 GPUs: an integrated Intel chip in addition to the
  # discrete NVIDIA card.
  # Further complicating things, it turns out that:
  #
  #   - The laptop screen is *only* connected to the integrated (Intel) GPU
  #   - The external ports (HDMI, Mini DisplayPort, and USB-C) are all *only*
  #     connected to the NVIDIA GPU.
  #
  # (at least, I believe that's the case, it's super difficult to find a
  # straightforward explanation of this)
  #
  # The internet is full of advice to start simple and *only* do integrated or
  # *only* do discrete before making things complicated, but if you want to be
  # able to use the laptop screen and the external ports, you *have* to use
  # both cards.
  # As I understand it, some machines have an actual device (a "mux") to toggle
  # which of your GPUs is connected to whatever output you're using.
  # Unfortunately, the Gazelle 16 does not have one of those, so if we want to
  # be able to use both the laptop screen *and* an external monitor, we're into
  # "muxless hybrid graphics" territory. As usual, the Arch Linux wiki is the
  # best resource on this: https://wiki.archlinux.org/title/PRIME
  # In particular, we're following the "Discrete card as primary GPU" scenario.
  hardware.system76.enableAll = true;
  hardware.opengl.enable = true;
  services.xserver.videoDrivers = [ "nvidia" "modesetting" ];
  # Unfortunately, nixos does not do the right then when you specify multiple
  # videoDrivers. See https://github.com/NixOS/nixpkgs/issues/108018 for
  # details. So, we just empty out the config and write it ourselves.
  services.xserver.config = lib.mkForce "";
  environment.etc."X11/xorg.conf.d/40-gazelle16-nvidia.conf".text = ''
    Section "OutputClass"
        Identifier "NVIDIA"
        MatchDriver "nvidia-drm"
        Driver "nvidia"
        Option "AllowEmptyInitialConfiguration"
        Option "PrimaryGPU" "Yes"
    EndSection
  '';
  # Configure our primary gpu (the NVIDIA card) to be able to use the Intel
  # (modesetting) card's outputs. This is just like the "Discrete card as
  # primary GPU" scenario described here:
  # https://wiki.archlinux.org/title/PRIME
  services.xserver.displayManager.setupCommands = ''
    ${pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource modesetting NVIDIA-0
    ${autoperipherals}/bin/autoperipherals
  '';

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
            "Noto" # has emojis
          ];
        })
      ];
      fontconfig = {
        defaultFonts = {
          monospace = [ "UbuntuMono Nerd Font Mono" ];
        };
      };
    };
  ##########

  nixpkgs.config.chromium.commandLineArgs = builtins.concatStringsSep " " [
    "--enable-features=VaapiVideoEncoder,VaapiVideoDecoder,CanvasOopRasterization"
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
    (pkgs.callPackage (import ../sources.nix).parsec-gaming { })
    mpv
    yt-dlp
    evince

    ### Compression/archives
    unzip

    ### Debugging
    arandr
    xorg.xkill
    xorg.xev
    libva-utils
    glxinfo
    pciutils

    ### Debugging fonts
    gucharmap

    # TODO: consolidate with xmonad
    alacritty
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
