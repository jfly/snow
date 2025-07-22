{ flake, ... }:
{
  imports = [
    flake.nixosModules.shared
    flake.nixosModules.nginx
    flake.nixosModules.syncthing
    ./boot.nix
    ./network.nix
    ./gpu.nix
    ./nas.nix
    ./backup
    ./jellyfin.nix
    ./cryptpad.nix
    ./vpn
    ./prometheus
    ./grafana.nix
    ./healthcheck.nix
    ./immich.nix
    ./remote-desktop.nix
    ./step-ca.nix
    ./vaultwarden.nix
    ./audiobookshelf.nix
    ./nextcloud.nix
    ./home-assistant
    ./ospi.nix
    ./manman
  ];

  networking.hostName = "fflewddur";

  # i18n stuff
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.xkb.layout = "us";

  # Enable ssh.
  services.openssh.enable = true;
}
