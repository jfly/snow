{ config, lib, pkgs, modulesPath, ... }:

let
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
      autoLogin.user = "jeremy";
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

  # Enable sound with pipewire.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # TODO: figure out how to enable native GPU, I know this machine has one!
  services.xserver.videoDrivers = [ "modesetting" ];
  services.xserver.useGlamor = true;

  environment.systemPackages = with pkgs; [
    alacritty
    dmenu
    qutebrowser
    jscrot
    viewnior
  ];

  programs.nm-applet.enable = true;

  systemd.user.services = {
    # TODO: run autoperipherals, load ~/.Xresources
    # TODO: enable numlock on boot
    # TODO: add blueman-applet
    # TODO: add xsettingsd
    # TODO: add gnome-keyring
    # TODO: add mcg
    # TODO: add volnoti

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
}
