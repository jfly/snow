{ flake, pkgs, ... }:

let
  identities = flake.lib.identities;
in
{
  imports = [
    flake.nixosModules.shared
    flake.nixosModules.nginx
    ./boot.nix
    ./network.nix
    ./containers.nix
    ./backup.nix
    ./dbs.nix
    ./dns.nix
    ./budget.nix
  ];

  fileSystems."/mnt/media" = {
    device = "fflewddur.ec:/";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.requires=network-online.target"
    ];
  };

  networking.hostName = "clark";

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
  users.mutableUsers = false;
  users.users.root = {
    openssh.authorizedKeys.keys = [
      identities.jfly
    ];
  };
  users.users.media-ro = {
    isNormalUser = true;
    createHome = false;

    openssh.authorizedKeys.keys = [
      identities.kent-kodi
    ];
  };

  # Some useful packages to have globally installed.
  environment.systemPackages = [
    pkgs.vim
    pkgs.git # Needed so we can push to repos hosted on this machine.
    (pkgs.callPackage ./beets.nix {
      beetsConfig = {
        # TODO: I had to manually run `mkdir -p /root/.local/state/beet/` before this would work.
        statefile = "/root/.local/state/beet/state.pickle";

        plugins = [
          "badfiles"
          "duplicates"
          "embedart"
          "fetchart"
          "fetchartist"
          "mbsync"
          "missing"
          "unimported"
          "convert"
        ];

        directory = "/mnt/media/music/jfly";
        library = "/mnt/media/music/jfly/beets.db";
        unimported = {
          ignore_extensions = "db jpg";
          ignore_subdirectories = "";
        };

        # I only use this plugin in order to remove embedded album art.
        embedart = {
          auto = "no";
        };

        fetchart = {
          auto = "yes";
          sources = "filesystem coverart itunes amazon albumart";
        };

        fetchartist = {
          # This is for compatibility with Navidrome: https://github.com/navidrome/navidrome/issues/394
          filename = "artist";
        };

        badfiles = {
          # Hacks to avoid dependencies on noisy third party checkers such as
          # https://aur.archlinux.org/packages/mp3val/). For now I'm just
          # interested in finding files that are in the database but not on the
          # filesystem.
          commands = {
            mp3 = "echo good";
            wma = "echo good";
            m4a = "echo good";
            flac = "echo good";
          };
        };
      };
    })
  ];
}
