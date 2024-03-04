{ ... }:

{
  # From https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi_4#Audio
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  # This option is broken right now. See https://github.com/NixOS/nixos-hardware/issues/703
  # hardware.raspberry-pi."4".audio.enable = true;
  # This workaround can be removed once ^ is resolved.
  boot.kernelParams = [ "snd_bcm2835.enable_hdmi=1" ];
}
