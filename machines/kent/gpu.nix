{ pkgs, ... }:
{
  # https://wiki.nixos.org/wiki/Accelerated_Video_Playback
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      # For older processors. `intel-media-driver` doesn't seem to work with
      # the Intel i5-3470T we have in this machine.
      intel-vaapi-driver

    ];
  };
}
