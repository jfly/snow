{ config, ... }:

{
  services.xserver.enable = true;
  services.displayManager.autoLogin = {
    enable = true;
    user = config.variables.kodiUsername;
  };
  services.xserver.windowManager.xmonad = {
    enable = true;
    extraPackages = hp: [ hp.xmonad-contrib hp.xmonad-extras ];
    config = builtins.readFile ./xmonad.hs;
  };
}
