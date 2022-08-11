# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  # We're runnning a real NixOS environment here: we don't need to wrap
  # our GUI programs with NixGl, yay!
  nopNixGL = wrap-me: wrap-me;
in

{
  nixpkgs = {
    system = "x86_64-linux";
    config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "parsec"
    ];
  };

  deployment.targetUser = "jeremy";
  nix.settings.trusted-users = [ "root" "@wheel" ];
  security.sudo.wheelNeedsPassword = false;
  deployment.allowLocalDeployment = true;

  imports =
    [
      ./hardware-configuration.nix # Include the results of the hardware scan.
      ./network.nix
      ./users.nix
      ./audio.nix
      ./desktop.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  swapDevices = [{ device = "/swapfile"; size = 2048; }];

  # i18n stuff
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.layout = "us";

  environment.systemPackages = with pkgs; [
    vim
    git
    ripgrep
  ] ++ (
    # Some hackiness to extract the derivations from the attrset in
    # dotfiles/my-nix.
    builtins.attrValues (
      lib.attrsets.filterAttrs
        (k: v: k != "override" && k != "overrideDerivation")
        (callPackage ../dotfiles/my-nix { wrapNixGL = nopNixGL; })
    )
  );

  services.logind.lidSwitch = "ignore";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
