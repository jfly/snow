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

  # Enable deployments by non-root user.
  nix.settings.trusted-users = [
    "root"
    "@wheel"
  ];

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
    ./pim
    ./fingerprint.nix
    ./android.nix
    ./development.nix
    ./syncthing.nix
    ./printers.nix
    ./fuse.nix
    ./laptop.nix
    ./garage-status.nix
    ./remote-builders.nix
    ./tor.nix
    ./waydroid.nix
    ./remote-fs.nix
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

  # This device is not online all the time.
  snow.monitoring.alertIfDown = false;

  swapDevices = [
    {
      device = "/swapfile";
      size = 2048;
    }
  ];

  # i18n stuff
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.xkb.layout = "us";

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandlePowerKey = "suspend";
  };
}
