{ agenix, agenix-rooter }:
{ config, lib, pkgs, ... }:

let identities = import ../../lib/identities.nix; # TODO: access via `self`
in
{
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
      agenix.nixosModules.default
      agenix-rooter.nixosModules.default
    ];

  age.rooter = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB+zwjwqpX+3HR/bgVR8O0xmTzNVaRvKhzuTJr7/wjSE";
    generatedForHostDir = ../../secrets;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

  variables.kodiUsername = "dallben";

  # i18n stuff
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.xkb.layout = "us";

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
