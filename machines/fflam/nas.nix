{
  pkgs,
  ...
}:

let
  # Want to add a new drive? See README.md for instructions.
  nasDriveUuids = {
    "/mnt/disk1" = "bdea6b72-18d2-479d-bd54-f4e85e24449c";
    "/mnt/disk2" = "9ce5e827-9e77-4aef-9d22-3b09bc0d512b";
    "/mnt/disk3" = "f17a98d0-6547-47f5-b9d1-08c1ca4a233a";
    "/mnt/disk4" = "dac09fb6-d300-4892-b83b-3acef83cc757";
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

  # Allow fflewddur to push backups here.
  users.users.root.openssh.authorizedKeys.keys = [
    (builtins.readFile ../../vars/shared/fflewddur-fflam-backup-ssh/key.pub/value)
  ];
}
