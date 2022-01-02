{ config, pkgs, ... }:

{
  # Use the latest kernel because the default (5.10) doesn't have this fix for
  # sound cards on NUCs:
  # https://github.com/torvalds/linux/commit/e81d71e343c6c62cf323042caed4b7ca049deda5
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enable audio
  hardware.pulseaudio.enable = true;
  users.users.${config.variables.kodiUsername}.extraGroups = [
    "audio"  # From https://nixos.wiki/wiki/PulseAudio#Enabling_PulseAudio
  ];
}
