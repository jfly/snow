{
  flake',
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
  security.sudo.wheelNeedsPassword = false;

  programs.nix-ld.enable = true;

  imports = [
    ./hardware-configuration.nix # Include the results of the hardware scan.
    ./hardware-configuration-custom.nix
    ./network.nix
    ./users.nix
    ./audio.nix
    inputs.home-manager.nixosModules.home-manager
    ./home-manager.nix
    ./shell
    ./desktop
    ./android.nix
    ./development.nix
    ./syncthing.nix
    ./printers.nix
    ./fuse.nix
    ./laptop.nix
    ./garage-status.nix
  ];

  # Use our fancy configured neovim rather than stock.
  snow.neovim.package = flake'.packages.neovim;

  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  age.rooter.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAgwlwF1H+tjq6ZFHBV5g1p6XCxRk8ee1uKvZr0eK+TP";

  # Add the nix cache running on fflewddur.
  nix.settings = {
    substituters = [ "https://cache.snow.jflei.com" ];
    # TODO: DRY up with fflewddur/binary-cache.nix
    trusted-public-keys = [ "cache.snow.jflei.com:K6CK1XYbt72oXnBNggcgDwxkeLUeyGtSui2e7ibziqc=" ];
  };

  # Flakes!
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
