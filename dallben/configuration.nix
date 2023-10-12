{ agenix, agenix-rooter, parsec-gaming }:
{ config, lib, pkgs, ... }:

let identities = import ../shared/identities.nix;
in
{
  # TODO: figure out a better pattern for sharing packages across a system
  #       definition. Perhaps using overlays?
  _module.args.myParsec = pkgs.callPackage ./parsec/derivation.nix { inherit parsec-gaming; };
  nixpkgs = {
    config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "parsec"
    ];
  };

  imports =
    [
      ./variables.nix
      # NUC specific stuff
      ./boot.nix
      ./gpu.nix
      # Hopefully more generic Linux desktop stuff
      ./network.nix
      ./audio.nix
      ./bluetooth.nix
      ./desktop
      ./kodi
      ./parsec
      agenix.nixosModules.default
      agenix-rooter.nixosModules.default
    ];

  age.rooter = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB+zwjwqpX+3HR/bgVR8O0xmTzNVaRvKhzuTJr7/wjSE";
    generatedForHostDir = ../agenix-rooter-reencrypted-secrets;
  };

  # Give gurgi ssh access so it can run stop_parsec.sh
  # TODO: lock down permissions so that's the *only* thing it can do.
  users.users.gurgi = {
    isNormalUser = true;
    extraGroups = [
      "wheel" # Enable `sudo` for the user.
    ];
    openssh.authorizedKeys.keys = [ identities.gurgi ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

  variables.kodiUsername = "dallben";
  networking.hostName = config.variables.kodiUsername;
  # Disable the firewall. Kodi needs to expose various ports to function, and
  # we're behind a NAT anyways...
  networking.firewall.enable = false;

  # i18n stuff
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.layout = "us";

  # Enable ssh.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # Allow ssh access as root user.
  users.users.root = {
    openssh.authorizedKeys.keys = [ identities.jfly ];
  };

  # Create a user with sudo and ssh access.
  security.sudo.wheelNeedsPassword = false;
  users.mutableUsers = false;
  users.users.${config.variables.kodiUsername} = {
    isNormalUser = true;
    extraGroups = [
      "wheel" # Enable `sudo` for the user.
    ];
    openssh.authorizedKeys.keys = [ identities.jfly ];
    hashedPassword = "$6$qZbruBYDeCvoleSI$6Qn9rUHVvutADJ7kxK9efrPLnNiW1dXgrdjrwFKIH338mq8A8dIk/tv/QV/kwrylK1GJtMW6qBsEkcszOh4f11";
    uid = 1000;
  };
}
