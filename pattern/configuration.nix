{ config, pkgs, lib, ... }:

let
  # We're runnning a real NixOS environment here: we don't need to wrap
  # our GUI programs with NixGl, yay!
  nopNixGL = wrap-me: wrap-me;
in

{
  snow.user = {
    name = "jeremy";
    uid = 1000;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  nixpkgs = {
    system = "x86_64-linux";
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
    ./home-manager.nix
    ./shell
    ./desktop.nix
    ./android.nix
    ./development.nix
    ./syncthing.nix
    ./printers.nix
    ./fuse.nix
    ./laptop.nix
  ];

  # Flakes!
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  swapDevices = [{ device = "/swapfile"; size = 2048; }];

  # i18n stuff
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.layout = "us";

  environment.systemPackages = with pkgs; [
    ripgrep
    (pkgs.callPackage ../shared/sd { })
  ] ++ (
    # Some hackiness to extract the derivations from the attrset in
    # shared/my-nix.
    builtins.attrValues (
      lib.attrsets.filterAttrs
        (k: v: k != "override" && k != "overrideDerivation")
        (callPackage ../shared/my-nix { wrapNixGL = nopNixGL; })
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
