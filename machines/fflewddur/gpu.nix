# Settings from <https://wiki.nixos.org/wiki/Nvidia>
{ config, lib, ... }:
{
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "nvidia-kernel-modules"
      "nvidia-settings"
      "nvidia-x11"
    ];

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    # "The default NVIDIA drivers no longer support Maxwell (GTX 1xxx) or older
    # GPUs. Pin the nvidia package to `
    # config.boot.kernelPackages.nvidiaPackages.legacy_580` for continued
    # support."
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
  };
}
