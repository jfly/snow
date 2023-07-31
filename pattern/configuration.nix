{ agenix, agenix-rooter, parsec-gaming, home-manager, knock-flake }:
{ config, pkgs, lib, ... }:

let knock = knock-flake.packages.${pkgs.system}.knock;
in
{
  _module.args.parsec-gaming = parsec-gaming;

  snow.user = {
    name = "jeremy";
    uid = 1000;
  };

  # As of 2023-05-26 sysdig doesn't compile with the latest kernel =(
  # https://docs.sysdig.com/en/docs/release-notes/sysdig-agent-release-notes/#added-support-for-kernel-version-63
  # mentions the kernel module getting an update to support Linux 6.3, but I
  # can't find any evidence of that over on https://github.com/draios/sysdig
  # TODO: wait and see what happens? There are a few unreleased commits over on
  # https://github.com/draios/sysdig/compare/0.31.5...dev, maybe those will fix
  # stuff up?
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  nixpkgs = {
    config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "parsec"
    ];
  };

  deployment.targetUser = config.snow.user.name;
  nix.settings.trusted-users = [ "root" "@wheel" ];
  security.sudo.wheelNeedsPassword = false;
  deployment.allowLocalDeployment = true;

  imports = [
    ./hardware-configuration.nix # Include the results of the hardware scan.
    ./hardware-configuration-custom.nix
    ./network.nix
    ./users.nix
    ./audio.nix
    home-manager.nixosModules.home-manager
    ./home-manager.nix
    ./shell
    ./desktop.nix
    ./android.nix
    ./development.nix
    ./syncthing.nix
    ./printers.nix
    ./fuse.nix
    ./laptop.nix
    agenix.nixosModules.default
    agenix-rooter.nixosModules.default
  ];

  age.rooter = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAgwlwF1H+tjq6ZFHBV5g1p6XCxRk8ee1uKvZr0eK+TP";
    generatedForHostDir = ../agenix-rooter-reencrypted-secrets;
  };

  # Add the nix cache running on fflewddur.
  nix.settings = {
    substituters = [ "https://cache.snow.jflei.com" ];
    # TODO: DRY up with fflewddur/binary-cache.nix
    trusted-public-keys = [ "cache.snow.jflei.com:K6CK1XYbt72oXnBNggcgDwxkeLUeyGtSui2e7ibziqc=" ];
  };

  # Flakes!
  nix.settings.experimental-features = [ "nix-command" "flakes" "repl-flake" ];

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

  swapDevices = [{ device = "/swapfile"; size = 2048; }];

  # i18n stuff
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.layout = "us";

  environment.systemPackages = with pkgs; [
    ripgrep
    (pkgs.callPackage ../shared/sd { })
    knock
  ] ++ (
    # Some hackiness to extract the derivations from the attrset in
    # shared/my-nix.
    builtins.attrValues (
      lib.attrsets.filterAttrs
        (k: v: k != "override" && k != "overrideDerivation")
        (callPackage ../shared/my-nix { })
    )
  );

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
