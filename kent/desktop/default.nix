{ ... }:
{
  # From https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi_4#With_GPU
  hardware.raspberry-pi."4".fkms-3d.enable = true;

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
