{ flake, ... }:
{
  imports = [
    flake.nixosModules.shared
    flake.nixosModules.syncthing
    ./boot.nix
    ./network.nix
    ./gpu.nix
    ./nas.nix
    ./backup
    ./jellyfin.nix
    ./zerotier
    ./kanidm
    ./prometheus
    ./grafana.nix
    ./healthcheck.nix
    ./immich.nix
    ./immichframe.nix
    ./remote-desktop.nix
    ./step-ca.nix
    ./vaultwarden.nix
    ./audiobookshelf.nix
    ./home-assistant
    ./ospi.nix
    ./manman
    ./whoami.nix
    ./miniflux.nix
    ./speedtest.nix
    ./brbd-sync.nix
    ./frigate.nix
    ./readeck.nix
    ./beets.nix
    ./irc-bouncer.nix
  ];

  networking.hostName = "fflewddur";
  snow.network.lan = {
    tld = "ec";
    # Keep this in sync with <routers/strider/files/etc/config/dhcp>.
    ip = "192.168.28.172";
  };

  # i18n stuff
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.xkb.layout = "us";

  # Enable ssh.
  services.openssh.enable = true;
}
