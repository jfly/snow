{
  flake,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    flake.nixosModules.zfs
  ];

  clan.core.vars.generators.nas = {
    prompts."password" = {
      persist = true;
      type = "hidden";
    };
  };

  # Mount various ZFS datasets. Note that `/mnt/bay` is *not* a parent dataset,
  # so any data in there will land on the rootfs. Don't put anything there! I
  # wonder if we could make it immutable somehow...
  fileSystems."/mnt/bay/archive" = {
    device = "bay/archive";
    fsType = "zfs";
    options = [
      # Don't block boot if we cannot mount this.
      "nofail"
      # But also do not allow anyone to write to it, even if the mount
      # fails (this will instead trigger another mount attempt).
      "x-systemd.automount"
    ];
  };
  fileSystems."/mnt/bay/media" = {
    device = "bay/media";
    fsType = "zfs";
    options = [
      "nofail"
      "x-systemd.automount"
    ];
  };
  fileSystems."/mnt/bay/restic" = {
    device = "bay/restic";
    fsType = "zfs";
    options = [
      "nofail"
      "x-systemd.automount"
    ];
  };

  # Make media accessible at `/mnt/media`. This is partially
  # historical, but also kind of a nice abstraction.
  fileSystems."/mnt/media" = {
    device = "/mnt/bay/media";
    fsType = "none";
    options = [
      "bind"
      "nofail"
      "x-systemd.automount"
    ];
  };

  users.users.archive = {
    isSystemUser = true;
    group = "bay";
  };

  # Set up Samba server (from https://wiki.nixos.org/wiki/Samba)
  services.samba = {
    enable = true;
    openFirewall = true;
    # `sambaFull` is compiled with avahi support, which is required for samba
    # to register mDNS records for auto discovery
    package = pkgs.sambaFull.override {
      # Workaround for <https://github.com/NixOS/nixpkgs/issues/442652>
      enableCephFS = false;
    };
    settings = {
      global = {
        "security" = "user";
        "workgroup" = "WORKGROUP";
        "server string" = config.networking.hostName;
        "netbios name" = config.networking.hostName;
        "use sendfile" = "yes";
        # Deny everyone, except for those listed in "hosts allow".
        "hosts deny" = "ALL";
        "hosts allow" = lib.concatStringsSep " " [
          "127.0.0.1"
          "[::1]"
          config.snow.subnets.colusa-trusted.ipv4
          config.snow.subnets.overlay.ipv6
        ];
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };

      archive = {
        path = "/mnt/bay/archive";
        "valid users" = "jfly rachel";
        browseable = "yes";
        writeable = "yes";
        "force user" = config.users.users.archive.name;
      };

      dangerzone = {
        path = "/mnt/bay/dangerzone";
        "valid users" = "jfly rachel";
        browseable = "yes";
        writeable = "yes";
        "force user" = config.users.users.archive.name;
      };

      media = {
        path = "/mnt/media";
        writeable = "yes";
        "valid users" = "jfly rachel dallben";
        "force group" = "media";
        "force create mode" = "0660"; # rw for user and group.
        "force directory mode" = "0770"; # rwx for user and group.
      };
    };
  };

  systemd.services.samba-smbd = {
    unitConfig = {
      RequiresMountsFor = [
        (lib.mapAttrsToList (key: setting: setting.path) (
          removeAttrs config.services.samba.settings [ "global" ]
        ))
      ];
    };
  };

  # Samba needs a corresponding unix user. Unfortunately, there is currently no
  # mechanism to declaratively manage sambda credentials. See
  # <machines/dallben/arr/mnt-media.nix>.
  users.users.dallben = {
    group = "media";
    isSystemUser = true;
  };

  # Advertise shares.
  services.avahi = {
    publish.enable = true;
    publish.userServices = true;
    nssmdns4 = true;
    enable = true;
    openFirewall = true;
  };

  # Advertise shares for Windows clients.
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  snow.backup.extraPaths = [
    "/mnt/bay/archive"
  ];
}
