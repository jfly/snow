{ ... }:
{
  services.xserver = {
    enable = true;

    windowManager.xmonad = {
      enable = true;
      extraPackages = hp: [
        hp.xmonad-contrib
        hp.xmonad-extras
      ];
      config = builtins.readFile ./xmonad.hs;
    };
  };
}
