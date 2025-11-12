{ pkgs, ... }:

{
  # Enable hardware accelerated video playback
  # (copied from <https://wiki.nixos.org/wiki/Accelerated_Video_Playback>)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };
  # Intel graphics
  services.xserver.videoDrivers = [ "modesetting" ];
}
