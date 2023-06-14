{ config, lib, pkgs, ... }:

rec {
  nixpkgs.system = "x86_64-linux";

  imports =
    [
      ./boot.nix
      ./network.nix
      ./containers.nix
      ./dbs.nix
      ./dns.nix
    ];

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
  services.xserver.layout = "us";

  # Enable ssh.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # Allow ssh access as root user.
  users.mutableUsers = false;
  users.users.root = {
    openssh.authorizedKeys.keys = [
      # Jeremy's public key
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDnasT8sq608RevJt+DzyQF4ppsYzq7P0yBxxaI8EjYsC1LxzZHqZpxRmz3iHYyy3ax4wmoak4Qy/dIvIH6l8R5rCab9ZRWXWKp+EYnn2MNUGFMolo4ark1UUll1+Dzm8saNvIMC7Dr5FIlrlQoP9jKOIDFM+cVTUOqwwyFU+IedetjmT47mXVQ/QHgsdDXM5SwKdtM8YGWxrhA3n4WgwmWSYQZyoSxdiQkoatABOqSgPcmczyZ7HqwajgL81n/Jaj8D6KVfJsOm/PU4O5MO5GU4ya6CcQVMn/elBfZIIsh+5rUyNH2GxBdT7luvHwAiHs/jWoyWmH5mr+6IG6nKGmhv2kRPaEfpvHoGo/gM6j/PvW18nynlWkajPqsy5D/3+4UoSPwPNNn9T0yFauExq+AReb88/Ixez6YH2jIRmtlIV4njKL8c7qdULnTrj8SZnz3tMiWgmY86+w+LsDcWHVADINk9rlUPGZcmTD06GLXZjNkWOvC/deLgNnApWTPpwEbZWzugeOtl/busMKob7acH1/F7rRB9nMj4Dtayjvth9Lbf8UDu7Hi8147ADxJJpVwSIIEKAFDeBPGqiuVnYm66dxdvjRzLmdf5LAGh9wy88FpV9btWeNoKSQt5gy7de2zVyBjix4l17ZbYtGiKEvhHJlVg7H8AlP6m9BbA6aeYw=="
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
          "mbsync"
          "missing"
          "unimported"
          "convert"
        ];

        directory = "/mnt/media/beets";
        library = "/mnt/media/beets/beets.db";
        unimported = {
          ignore_extensions = "db jpg";
        };

        # I only use this plugin in order to remove embedded album art.
        embedart = {
          auto = "no";
        };

        fetchart = {
          auto = "yes";
          sources = "filesystem coverart itunes amazon albumart";
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
