{ config, lib, pkgs, ... }:

{
  nixpkgs.system = "aarch64-linux";

  imports =
    [
      ./nas.nix
      ./snow-backup.nix
    ];

  boot = {
    kernelPackages = pkgs.linuxPackages_rpi4;
    tmpOnTmpfs = true;
    initrd.availableKernelModules = [ "usbhid" "usb_storage" ];
    # ttyAMA0 is the serial console broken out to the GPIO
    kernelParams = [
      "8250.nr_uarts=1"
      "console=ttyAMA0,115200"
      "console=tty1"
      # Some gui programs need this
      "cma=128M"
    ];
  };

  # https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1008362877
  nixpkgs.overlays = [
    (final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  # I had a lot of trouble getting an sdcard to build, and then ran into
  # different problems when trying to deploy remotely.
  # https://discourse.nixos.org/t/raspberry-pi-boot-loader-raspberrypi-firmwareconfig-not-taking-effect/19692/3
  # https://discourse.nixos.org/t/raspberrypi-boot-loader-still-using-extlinux/20119/2
  # https://github.com/NixOS/nixpkgs/issues/173948
  #
  # Copied from nixos/modules/installer/sd-card/sd-image-raspberrypi.nix
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  # I believe this `boot.loader.raspberryPi` stuff is deprecated? Although I
  # can't find a good source to say that.
  # It certainly doesn't play nicely with the sd card generation code in
  # nixos/modules/installer/sd-card/sd-image-aarch64.nix.
  # boot.loader.raspberryPi = {
  #   enable = true;
  #   version = 4;
  # };

  # Required for the Wireless firmware
  hardware.enableRedistributableFirmware = true;

  networking = {
    hostName = "fflam";
    networkmanager = {
      enable = true;
    };
    # Disable the firewall. I'm just not used to having one, and we're behind a NAT anyways...
    firewall.enable = false;
  };

  # Enable ssh.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # Allow ssh access as root user.
  users.users.root = {
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDnasT8sq608RevJt+DzyQF4ppsYzq7P0yBxxaI8EjYsC1LxzZHqZpxRmz3iHYyy3ax4wmoak4Qy/dIvIH6l8R5rCab9ZRWXWKp+EYnn2MNUGFMolo4ark1UUll1+Dzm8saNvIMC7Dr5FIlrlQoP9jKOIDFM+cVTUOqwwyFU+IedetjmT47mXVQ/QHgsdDXM5SwKdtM8YGWxrhA3n4WgwmWSYQZyoSxdiQkoatABOqSgPcmczyZ7HqwajgL81n/Jaj8D6KVfJsOm/PU4O5MO5GU4ya6CcQVMn/elBfZIIsh+5rUyNH2GxBdT7luvHwAiHs/jWoyWmH5mr+6IG6nKGmhv2kRPaEfpvHoGo/gM6j/PvW18nynlWkajPqsy5D/3+4UoSPwPNNn9T0yFauExq+AReb88/Ixez6YH2jIRmtlIV4njKL8c7qdULnTrj8SZnz3tMiWgmY86+w+LsDcWHVADINk9rlUPGZcmTD06GLXZjNkWOvC/deLgNnApWTPpwEbZWzugeOtl/busMKob7acH1/F7rRB9nMj4Dtayjvth9Lbf8UDu7Hi8147ADxJJpVwSIIEKAFDeBPGqiuVnYm66dxdvjRzLmdf5LAGh9wy88FpV9btWeNoKSQt5gy7de2zVyBjix4l17ZbYtGiKEvhHJlVg7H8AlP6m9BbA6aeYw==" ];
    password = pkgs.deage.string ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBsN0pVMmNsK1V3SFdHK0Ri
      eGQzcGNLT1NTSkxJWklwQWF2RmtLaThlZEJjCnVaRnRnaHZRMDR5NHhHSUhHNUFS
      UlFGVldZOE9ua0ttVFJDVkkzVWs5VGsKLS0tIGhETG8wSUJ1OE8rTmwwVWN2OXpv
      WnFoUFJVVjVOSzNZVElVMlhIM1g4U1UKTus3n+ainTFU+Z+V1z4pkDcb9kWJK+rw
      jOi5j4u4SLapeSbFelqut0ki
      -----END AGE ENCRYPTED FILE-----
    '';
  };

  # Assuming this is installed on top of the disk image.
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
  };
  powerManagement.cpuFreqGovernor = "ondemand";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
