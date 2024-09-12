# This file contains hardware specific tweaks. I don't put them in
# hardware-configuration.nix just so we can easily regenerate/clobber it.
{ pkgs, ... }:

{
  ### GPU
  # Intel graphics
  # Enable hardware accelerated video playback
  # (copied from https://nixos.wiki/wiki/Accelerated_Video_Playback)
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware.graphics = {
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

  ### Trackpoint
  environment.etc."X11/xorg.conf.d/20-trackpoint.conf".text = ''
    Section "InputClass"
      Identifier "Trackpoint Acceleration"
      # See https://wiki.archlinux.org/index.php/Mouse_acceleration#with_libinput.
      MatchIsPointer "yes"
      Option "AccelProfile" "adaptive"
      Option "AccelSpeed" "-0.5"
    EndSection
  '';

  ### Keep every other misc thing up to date
  services.fwupd.enable = true;

  ### Fix ethernet on CalDigit TS4 dock
  # This dock exposes the ethernet device via PCI tunneling, which requires us to trust the attached Thunderbolt device.
  # This udev rule comes from
  # https://docs.kernel.org/admin-guide/thunderbolt.html#dma-protection-utilizing-iommu,
  # but read the whole page to understand the nuances here, and why this is safe to do.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTRS{iommu_dma_protection}=="1", ATTR{authorized}=="0", ATTR{authorized}="1"
  '';
}
