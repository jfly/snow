{ flake, ... }:
{
  imports = [
    flake.nixosModules.shared
    ./boot.nix
    ./network.nix
    ./gpu.nix
    ./nas.nix
    ./backup.nix
    ./binary-cache.nix
    ./jellyfin.nix
    ./cryptpad.nix
  ];

  age.rooter.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBu1H1RFGjmzpUncYWUGwCDcQPVfgAxH4S2yYPt46a/5";

  system.stateVersion = "21.11";

  networking.hostName = "fflewddur";
  # Disable the firewall. I'm not used to having one, and we're behind a NAT anyways...
  networking.firewall.enable = false;

  # i18n stuff
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.xkb.layout = "us";

  # Enable ssh.
  services.openssh.enable = true;

  users.users.root.hashedPassword = "$6$qZbruBYDeCvoleSI$6Qn9rUHVvutADJ7kxK9efrPLnNiW1dXgrdjrwFKIH338mq8A8dIk/tv/QV/kwrylK1GJtMW6qBsEkcszOh4f11";
}
