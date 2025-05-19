{
  flake,
  inputs,
  pkgs,
  ...
}:

{
  snow.user = {
    name = "jeremy";
    uid = 1000;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  clan.core.networking = {
    buildHost = "jfly@localhost";
    targetHost = "jfly@pattern.ec";
  };

  # Enable deployments by non-root user.
  nix.settings.trusted-users = [
    "root"
    "@wheel"
  ];
  security.sudo.wheelNeedsPassword = false;

  programs.nix-ld.enable = true;

  imports = [
    flake.nixosModules.shared
    ./hardware-configuration.nix # Include the results of the hardware scan.
    ./hardware-configuration-custom.nix
    ./network.nix
    ./users.nix
    ./audio.nix
    inputs.home-manager.nixosModules.home-manager
    ./home-manager.nix
    ./sshd.nix
    ./shell
    ./desktop
    ./android.nix
    ./development.nix
    ./syncthing.nix
    ./printers.nix
    ./fuse.nix
    ./laptop.nix
    ./garage-status.nix
    ./remote-builders.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  # Keep only a finite number of boot configurations. This prevents /boot from
  # filling up.
  # https://nixos.wiki/wiki/Bootloader#Limiting_amount_of_entries_with_grub_or_systemd-boot
  boot.loader.systemd-boot.configurationLimit = 100;
  boot.loader.efi.canTouchEfiVariables = true;
  # nixos doesn't clear out /tmp on each boot. I'm used to it being a tmpfs
  # (`boot.tmp.useTmpfs = true`), but nix-shell uses it, and it needs a *lot*
  # of space, and I'm not sure I want to allocate that much ram?
  boot.tmp.cleanOnBoot = true;

  swapDevices = [
    {
      device = "/swapfile";
      size = 2048;
    }
  ];

  # i18n stuff
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.xkb.layout = "us";

  services.logind.lidSwitch = "ignore";
  services.logind.extraConfig = ''
    HandlePowerKey=suspend
  '';

  # https://wiki.nixos.org/wiki/Samba#Samba_Client
  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."/mnt/archive" = {
    device = "//fflewddur.ec/archive";
    fsType = "cifs";
    options = [
      "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s"
    ];
  };
}
