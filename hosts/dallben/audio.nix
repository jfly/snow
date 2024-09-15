{ config, ... }:

{
  # Enable audio
  hardware.pulseaudio.enable = true;
  users.users.${config.variables.kodiUsername}.extraGroups = [
    "audio" # From https://nixos.wiki/wiki/PulseAudio#Enabling_PulseAudio
  ];
}
