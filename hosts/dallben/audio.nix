{ config, ... }:

{
  # Enable audio
  services.pipewire.enable = true;
  users.users.${config.variables.kodiUsername}.extraGroups = [
    "audio" # From https://nixos.wiki/wiki/PulseAudio#Enabling_PulseAudio
  ];
}
