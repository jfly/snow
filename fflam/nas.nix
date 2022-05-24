{ config, pkgs, ... }:

let
  # Want to add a new drive? See fflewddur's README.md for instructions.
  nas_drive_uuids = {
    "/mnt/disk1" = "ead4242e-e2c5-479a-b14f-2a0101200d7f";
    "/mnt/disk2" = "f17a98d0-6547-47f5-b9d1-08c1ca4a233a";
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
        "allow_other"
        "use_ino"
        "cache.files=partial"
        "dropcacheonclose=true"
        "category.create=mfs"
        # For NFS: https://github.com/trapexit/mergerfs#can-mergerfs-mounts-be-exported-over-nfs
        "noforget"
        "inodecalc=path-hash"
        # Useful to preserve permissions with so many different applications
        # writing to the shared filesystem. This may not be necessary as the
        # writes start coming in over NFS instead?
        "posix_acl=true"
      ];
    };
  };
}
