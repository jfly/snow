{ config, lib, pkgs, ... }:

{
  nixpkgs.system = "aarch64-linux";

  boot = {
    # Note: we're not using the pkgs.linuxPackages_rpi3 kernel here, it prints
    # out warnings about writing to read-only memory.
    # See https://github.com/NixOS/nixpkgs/issues/200326. https://discourse.nixos.org/t/nixos-raspberry-pi-no-hdmi-during-boot/23100 links to
    # https://github.com/cwi-foosball/foosball/blob/3f68fa2da74b07e756f86e689216dd627d66e065/modules/submodules/config_rasp_3B.nix#L35,
    # which suggests just using the latest kernel.
    #
    # # kernelPackages = pkgs.linuxPackages_rpi3;
    #
    # Unfortunately, the latest kernel doesn't work either: Kernel 6.2 is not
    # marked as "safe" to use with ZFS.
    # I'm unclear on why there's any ZFS involved in this raspberry pi setup at
    # all...
    #
    # # kernelPackages = pkgs.linuxPackages_latest;
    #
    # So, we're stuck with Linux 6.1 for now:
    kernelPackages = pkgs.linuxPackages_6_1;

    tmpOnTmpfs = true;
    initrd.kernelModules = [ "vc4" "bcm2835_dma" "i2c_bcm2835" ];
  };

  # https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1008362877
  nixpkgs.overlays = [
    (final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  # Needed for the virtual console to work on the RPi 3, as the default of 16M
  # doesn't seem to be enough. If X.org behaves weirdly (I only saw the cursor)
  # then try increasing this to 256M.
  # https://labs.quansight.org/blog/2020/07/nixos-rpi-wifi-router
  # On some kernels (not sure if it is fixed on 6.0.2) this parameter has priority lower than the deviceTree
  # so if it fails below how to change the device tree
  boot.kernelParams = [ "cma=256M" "console=tty0" ];

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
  #   version = 3;
  #   uboot.enable = true;
  #   # https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi_3#Audio
  #   firmwareConfig = ''
  #     dtparam=audio=on
  #   '';
  # };

  # Required for the Wireless firmware
  hardware.enableRedistributableFirmware = true;

  # Set up network.
  networking = {
    hostName = "kent";
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

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
    # Disabled for now because the pi won't boot if it starts up with an external usb drive attached.
    # u-boot crashes with an "Request sense return 02 04 01" error.
    "/mnt/media" = {
      device = "/dev/disk/by-uuid/c2a87d66-6f7a-4e29-86e9-f227114affbb";
      fsType = "ext4";
      options = [
        "noatime"
        # Do not mount the device until it's accessed:
        # https://wiki.archlinux.org/title/fstab#Local_partition
        "noauto"
        "x-systemd.automount"
        "x-systemd.device-timeout=1ms"
      ];
    };
  };

  # Create a swap file. I'm not sure if this is a good idea for a Raspberry Pi
  # 3B or not. The original sd card died and ended up read only, see
  # https://unix.stackexchange.com/a/455165.
  # Long SO thread about all of this:
  # https://raspberrypi.stackexchange.com/questions/169/how-can-i-extend-the-life-of-my-sd-card
  # Linked to from https://reprage.com/post/what-are-the-best-sd-cards-to-use-in-a-raspberry-pi
  swapDevices = [
    {
      device = "/swapfile";
      size = 2048;
    }
  ];

  # Set up printer
  services.printing = {
    enable = true;
    defaultShared = true;
    browsing = true;

    # brlaser doesn't explicitly mention the Brother HL-2240, but according to
    # https://github.com/pdewacht/brlaser/issues/136, *any* entry marked
    # 'brlaser' works? :shrug:
    drivers = [ pkgs.brlaser ];

    # Allow access from outside this machine.
    allowFrom = [ "all" ];
    listenAddresses = [ "*:631" ];
  };
  hardware.printers.ensurePrinters = [
    {
      name = "brother";
      location = "man cave";
      description = "brother hl-2240";
      deviceUri = "usb://Brother/HL-2240%20series?serial=J1N651698";
      # brlaser doesn't explicitly mention the Brother HL-2240, but according to
      # https://github.com/pdewacht/brlaser/issues/136, *any* entry marked
      # 'brlaser' works? :shrug:
      model = "drv:///brlaser.drv/br2220.ppd";
    }
  ];
  services.avahi = {
    enable = true;
    nssmdns = true;
    publish = {
      enable = true;
      userServices = true;
    };

  };

  # Set up samba (from https://nixos.wiki/wiki/Samba#Printer_sharing)
  services.samba = {
    enable = true;
    package = pkgs.sambaFull;
    openFirewall = true; # Automatically open firewall ports
    extraConfig = ''
      load printers = yes
      printing = cups
      printcap name = cups
    '';
    shares = {
      printers = {
        comment = "All Printers";
        path = "/var/spool/samba";
        public = "yes";
        browseable = "yes";
        # to allow user 'guest account' to print.
        "guest ok" = "yes";
        writable = "no";
        printable = "yes";
        "create mode" = 0700;
      };
    };
  };
  systemd.tmpfiles.rules = [
    "d /var/spool/samba 1777 root root -"
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
