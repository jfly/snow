{ ... }:

{
  services.xserver.enable = true;
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "dallben";
  services.xserver.windowManager.xmonad = {
    enable = true;
    extraPackages = hp: [ hp.xmonad-contrib hp.xmonad-extras ];
    config = builtins.readFile ./xmonad.hs;
  };
}
