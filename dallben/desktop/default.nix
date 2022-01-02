{ config, ... }:

{
  services.xserver.enable = true;
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = config.variables.kodiUsername;
  services.xserver.windowManager.xmonad = {
    enable = true;
    extraPackages = hp: [ hp.xmonad-contrib hp.xmonad-extras ];
    config = builtins.readFile ./xmonad.hs;
  };
}
