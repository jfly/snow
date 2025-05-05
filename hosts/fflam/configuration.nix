{ flake, ... }:

let
  identities = flake.lib.identities;
in
{
  networking.hostName = "fflam";
  system.stateVersion = "24.05";
  boot.loader.grub.enable = true;
  services.openssh.enable = true;

  imports = [
    flake.nixosModules.shared
    ./hardware-configuration.nix
    ./network.nix
    ./disko-config.nix
    ./mail.nix
  ];

  # Enable deployments by non-root user.
  nix.settings.trusted-users = [ "@wheel" ];
  security.sudo.wheelNeedsPassword = false;

  users.users.fflam = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ identities.jfly ];
  };

  age.rooter.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIME4wpWrY4RYMhtx+B+eFb8HPTEIEv4DfXA75DcddffS";
}
