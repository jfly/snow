{ config, pkgs, ... }:

let
  # Want to add a new drive? See fflewddur's README.md for instructions.
  nas_drive_uuids = {
    "/mnt/disk1" = "f17a98d0-6547-47f5-b9d1-08c1ca4a233a";
    "/mnt/disk2" = "9ce5e827-9e77-4aef-9d22-3b09bc0d512b";
    "/mnt/disk3" = "20a88b0b-3f2e-4579-8f86-a47d7b5b343a";
  };
in
{
  environment.systemPackages = with pkgs; [
    mergerfs
    mergerfs-tools
  ];

  fileSystems = (builtins.mapAttrs
    (mnt_path: uuid: {
      device = "/dev/disk/by-uuid/${uuid}";
      fsType = "ext4";
      options =
        [ "rw" "user" "auto" ];
    })
    nas_drive_uuids) // {
    "/mnt/media" = {
      device = builtins.concatStringsSep ":" (builtins.attrNames nas_drive_uuids);
      fsType = "fuse.mergerfs";
      options = [
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
    };
  };
}
