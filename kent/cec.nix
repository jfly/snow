{ pkgs, ... }:

# Copied from https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi_4#HDMI-CEC
{
  # an overlay to enable raspberrypi support in libcec, and thus cec-client
  nixpkgs.overlays = [
    (self: super: { libcec = super.libcec.override { withLibraspberrypi = true; }; })
  ];

  # install libcec, which includes cec-client (requires root or "video" group, see udev rule below)
  # scan for devices: `echo 'scan' | cec-client -s -d 1`
  # set pi as active source: `echo 'as' | cec-client -s -d 1`
  environment.systemPackages = with pkgs; [
    libcec
  ];

  # Ensure that /dev/vchiq is accessible by the "video" group, and add the Kodi
  # user to the that group.
  services.udev.extraRules = ''
    KERNEL=="vchiq",GROUP="video",MODE="0660"
  '';
  users.users.kent.extraGroups = [ "video" ];
}
