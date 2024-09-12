{ config, pkgs, ... }:

let
  inherit (pkgs.lib)
    mapAttrsToList
    imap1
    ;
  inherit (builtins)
    attrNames
    concatMap
    concatStringsSep
    ;

  # Want to add a new drive? See fflewddur's README.md for instructions.
  nasDriveUuids = [
    "f17a98d0-6547-47f5-b9d1-08c1ca4a233a"
    "9ce5e827-9e77-4aef-9d22-3b09bc0d512b"
    "20a88b0b-3f2e-4579-8f86-a47d7b5b343a"
  ];
  diskMountInfos = imap1
    (index: uuid: {
      what = "/dev/disk/by-uuid/${uuid}";
      where = "/mnt/disk${toString index}";
      systemdUnitName = "mnt-disk${toString index}.mount";
    })
    nasDriveUuids;
  diskWheres = map ({ where, ... }: where) diskMountInfos;
  diskMountNames = map ({ systemdUnitName, ... }: systemdUnitName) diskMountInfos;
in
{
  environment.systemPackages = with pkgs; [
    mergerfs
    mergerfs-tools
  ];

  systemd.mounts = (
    map
      ({ what, where, ... }: {
        inherit what where;
        type = "ext4";
        options = concatStringsSep "," [ "rw" "user" ];
      })
      diskMountInfos
  ) ++ [
    {
      what = concatStringsSep ":" diskWheres;
      where = "/mnt/nexus";
      type = "fuse.mergerfs";
      bindsTo = diskMountNames;
      after = diskMountNames;
      options = concatStringsSep "," [
        # From https://github.com/trapexit/mergerfs#basic-setup "You need mmap"
        # (sqlite needs mmap, home-assistant uses sqlite)
        "cache.files=partial"
        "dropcacheonclose=true"
        "category.create=mfs"
        # For NFS: https://github.com/trapexit/mergerfs#can-mergerfs-mounts-be-exported-over-nfs
        "noforget"
        "inodecalc=path-hash"
        # For kodi's "fasthash" functionality: https://github.com/trapexit/mergerfs#tips--notes
        "func.getattr=newest"
      ];
    }
  ];

  systemd.automounts = (
    map
      ({ where, ... }: {
        inherit where;
        wantedBy = [ "multi-user.target" ];

      })
      diskMountInfos
  ) ++ [
    {
      where = "/mnt/nexus";
      wantedBy = [ "multi-user.target" ];
    }
  ];

  # A user specifically for anonymous samba access.
  users = {
    groups.sc = { };
    users.sc = {
      isSystemUser = true;
      group = "sc";
    };
  };

  # Set up Samba server (from https://nixos.wiki/wiki/Samba#Samba_Server)
  services.samba-wsdd = {
    enable = true; # make shares visible for windows 10 clients
    openFirewall = true;
  };
  services.samba = {
    enable = true;
    openFirewall = true;
    securityType = "user";
    extraConfig = ''
      workgroup = WORKGROUP
      server string = kent
      netbios name = kent
      security = user
      use sendfile = yes
      # note: localhost is the ipv6 localhost ::1
      hosts allow = 192.168.0. 127.0.0.1 localhost
      hosts deny = 0.0.0.0/0
      guest account = nobody
      map to guest = bad user
    '';
    shares = {
      sc = {
        path = "/mnt/nexus/sc";
        browseable = "yes";
        "guest ok" = "yes";
        "force user" = "sc";
        "writeable" = "yes";
      };
      media = {
        path = "/mnt/nexus/media";
        browseable = "yes";
        "guest ok" = "yes";
        # Every user ("other") has read-only access to media, so the "sc" user
        # is a good choice (they aren't a member of the "media" group which
        # does have write access).
        "force user" = "sc";
        "read only" = "yes";
      };
    };
  };
}
