{ flake, pkgs, ... }:

let
  identities = flake.lib.identities;
in
{
  imports = [
    flake.nixosModules.shared
    ./boot.nix
    ./network.nix
    ./containers.nix
    ./backup.nix
    ./dbs.nix
    ./dns.nix
    ./pr-tracker.nix
  ];

  age.rooter.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFeLzY4y2R5GzsHBeuESH9ejQQlciFC7pfru3pdBMaAR";

  fileSystems."/mnt/media" = {
    device = "fflewddur:/";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.requires=network-online.target"
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

  networking.hostName = "clark";
  # Disable the firewall. I'm not used to having one, and we're behind a NAT anyways...
  networking.firewall.enable = false;

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
    hashedPassword = "$y$j9T$93csyGgKMJEP44ZTrFAAj0$qQ/4/ha0rORCNY/V3OTllm45sSUDqJSW3cRaSIoENb2";
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
    pkgs.git # needed so we can push to repos hosted on this machine
    (pkgs.callPackage ./beets.nix {
      beetsConfig = {
        # TODO: i had to manually run `mkdir -p /root/.local/state/beet/` before this would work
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

        directory = "/mnt/media/music";
        library = "/mnt/media/music/beets.db";
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
          # Hacks to avoid deps on noisy third party checkers such as
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
