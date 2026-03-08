{ flake, ... }:
{
  imports = [
    flake.nixosModules.shared
    ./boot.nix
    ./network.nix
    ./focus-dns.nix
  ];

  networking.hostName = "clark";

  # i18n stuff
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.xkb.layout = "us";
}
