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
}
