{ config, pkgs, lib, ... }:

{
  config = lib.mkIf (config.specialisation != { })
    {
      system.nixos.tags = [ "nvidia-gpu" ];
      # This is a System76 Gazelle 16 with an NVIDIA RTX 3060, which means we have
      # support for 1x DisplayPort 1.4 over USB-C:
      # https://tech-docs.system76.com/models/gaze16/README.html
      # This also means we have 2 GPUs: an integrated Intel chip in addition to the
      # discrete NVIDIA card.
      # Further complicating things, it turns out that:
      #
      #   - The laptop screen is *only* connected to the integrated (Intel) GPU
      #   - The external ports (HDMI, Mini DisplayPort, and USB-C) are all *only*
      #     connected to the NVIDIA GPU.
      #
      # (at least, I believe that's the case, it's super difficult to find a
      # straightforward explanation of this)
      #
      # The internet is full of advice to start simple and *only* do integrated or
      # *only* do discrete before making things complicated, but if you want to be
      # able to use the laptop screen and the external ports, you *have* to use
      # both cards.
      # As I understand it, some machines have an actual device (a "mux") to toggle
      # which of your GPUs is connected to whatever output you're using.
      # Unfortunately, the Gazelle 16 does not have one of those, so if we want to
      # be able to use both the laptop screen *and* an external monitor, we're into
      # "muxless hybrid graphics" territory. As usual, the Arch Linux wiki is the
      # best resource on this: https://wiki.archlinux.org/title/PRIME
      # In particular, we're following the "Discrete card as primary GPU" scenario.
      hardware.nvidia.modesetting.enable = true;
      services.xserver.videoDrivers = lib.mkDefault [ "nvidia" "modesetting" ];
      # Unfortunately, nixos does not do the right thing when you specify multiple
      # videoDrivers. See https://github.com/NixOS/nixpkgs/issues/108018 for
      # details. So, we just empty out the config and write it ourselves.
      services.xserver.config = lib.mkForce "";
      environment.etc."X11/xorg.conf.d/40-gazelle16-nvidia.conf".text = lib.mkDefault ''
        Section "OutputClass"
            Identifier "NVIDIA"
            MatchDriver "nvidia-drm"
            Driver "nvidia"
            Option "AllowEmptyInitialConfiguration"
            Option "PrimaryGPU" "Yes"
        EndSection
      '';
      # Configure our primary gpu (the NVIDIA card) to be able to use the Intel
      # (modesetting) card's outputs. This is just like the "Discrete card as
      # primary GPU" scenario described here:
      # https://wiki.archlinux.org/title/PRIME
      services.xserver.displayManager.setupCommands = lib.mkBefore ''
        ${pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource modesetting NVIDIA-0
      '';
    };
}
