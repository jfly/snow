{ config, lib, pkgs, modulesPath, ... }:

{
  # high-resolution display
  hardware.video.hidpi.enable = true;

  # Enable hardware accelerated video playback
  # (copied from https://nixos.wiki/wiki/Accelerated_Video_Playback)
  # TODO <<< https://github.com/NixOS/nixos-hardware/blob/master/common/cpu/intel/kaby-lake/default.nix >>>
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
  # Intel graphics
  services.xserver.videoDrivers = [ "modesetting" ];
  services.xserver.useGlamor = true;
}
