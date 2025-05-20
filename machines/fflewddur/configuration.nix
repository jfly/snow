{ flake, ... }:
{
  imports = [
    flake.nixosModules.shared
    flake.nixosModules.monitoring
    ./boot.nix
    ./nginx.nix
    ./network.nix
    ./gpu.nix
    ./nas.nix
    ./backup
    ./jellyfin.nix
    ./cryptpad.nix
    ./syncthing.nix
    ./vpn.nix
    ./prometheus
    ./grafana.nix
    ./healthcheck.nix
    ./immich.nix
    ./remote-desktop.nix
  ];

  networking.hostName = "fflewddur";
  networking.domain = "ec";
  clan.core.networking.targetHost = "jfly@fflewddur.ec";

  # i18n stuff
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.xkb.layout = "us";

  # Enable ssh.
  services.openssh.enable = true;
}
