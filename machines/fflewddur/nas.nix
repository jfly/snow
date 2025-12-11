{
  lib,
  config,
  pkgs,
  ...
}:

let
  # Want to add a new drive? See README.md for instructions.
  nasDriveUuids = {
    "/mnt/disk1" = "3d9fbde5-f6ae-49e7-8f13-abe194fbf17a";
    "/mnt/disk2" = "dac09fb6-d300-4892-b83b-3acef83cc757";
    "/mnt/disk3" = "54bf0c49-f945-4905-8bc5-d1f01f305741";
  };
in
{
  environment.systemPackages = with pkgs; [
    mergerfs
    mergerfs-tools
  ];

  fileSystems =
    (builtins.mapAttrs (_mntPath: uuid: {
      device = "/dev/disk/by-uuid/${uuid}";
      fsType = "ext4";
      options = [
        "rw"
        "user"
        "auto"
      ];
    }) nasDriveUuids)
    // {
      "/mnt/bay" = {
        device = builtins.concatStringsSep ":" (builtins.attrNames nasDriveUuids);
        fsType = "fuse.mergerfs";
        options = [
          # From https://github.com/trapexit/mergerfs#basic-setup "You don't need mmap"
          "cache.files=off"
          "dropcacheonclose=true"
          "category.create=mfs"
          # For NFS: https://github.com/trapexit/mergerfs#can-mergerfs-mounts-be-exported-over-nfs
          "noforget"
          "inodecalc=path-hash"
          # For kodi's "fasthash" functionality: https://github.com/trapexit/mergerfs#tips--notes
          "func.getattr=newest"
        ];
      };
      # Set up a bind mount so /mnt/bay/media is accessible at /mnt/media.
      # Why? Partly historical, but this also provides a nice abstraction.
      "/mnt/media" = {
        device = "/mnt/bay/media";
        options = [ "bind" ];
      };
    };

  users.users.archive = {
    isSystemUser = true;
    group = "bay";
  };

  users.users.dallben = {
    group = "media";
    isNormalUser = true; # Not a real human, but necessary to ssh.
    openssh.authorizedKeys.keys = [
      (builtins.readFile ../../vars/shared/dallben-ssh/key.pub/value)
    ];
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

      media-writer = {
        path = "/mnt/media";
        writeable = "yes";
        "valid users" = "dallben";
        "force group" = "media";
        "force create mode" = "0660"; # rw for user and group.
        "force directory mode" = "0770"; # rwx for user and group.
      };
    };
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

  snow.backup.paths = [
    "/mnt/bay/archive"
    # TODO: stop backing this up. Right now, we just need the
    # `/var/lib/samba/private/passdb.tdb` file with the samba users + hashed
    # passwords. Either managed those users declaratively, or integrate Samba
    # with some other auth provider that can handle this state for us (maybe
    # someday <https://github.com/kanidm/kanidm/issues/2627>).
    "/var/lib/samba"
  ];
}
