{ pkgs, ... }:

{
  # Intel graphics
  # Enable hardware accelerated video playback
  # (copied from https://nixos.wiki/wiki/Accelerated_Video_Playback)
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # Disabling PSR as a workaround for lag issues.
  # See https://bbs.archlinux.org/viewtopic.php?id=279885
  # and https://wiki.archlinux.org/title/intel_graphics#Screen_flickering
  boot.kernelParams = [ "i915.enable_psr=0" ];
}
