{ ... }:
{
  services.xserver = {
    enable = true;

    displayManager.autoLogin.enable = true;
    displayManager.autoLogin.user = "kent";
    windowManager.xmonad = {
      enable = true;
      extraPackages = hp: [ hp.xmonad-contrib hp.xmonad-extras ];
      config = builtins.readFile ./xmonad.hs;
    };
  };
}
