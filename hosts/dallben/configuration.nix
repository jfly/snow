{ flake, ... }:

let
  identities = flake.lib.identities;
in
{
  networking.hostName = "dallben";
  time.timeZone = "America/Los_Angeles";
  system.stateVersion = "21.11";
  services.openssh.enable = true;
  #<<< TODO: remove >>>

  # Allow ssh access as root user.
  users.users.root = {
    openssh.authorizedKeys.keys = [ identities.jfly ];
  };

  imports = [
    flake.nixosModules.shared
    ./hardware-configuration.nix
    ./boot.nix
    ./gpu.nix
    ./bluetooth.nix
    flake.nixosModules.xmonad-basic
    flake.nixosModules.kodi-colusita
  ];

  age.rooter.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB+zwjwqpX+3HR/bgVR8O0xmTzNVaRvKhzuTJr7/wjSE";
}
