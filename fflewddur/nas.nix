{ config, pkgs, ... }:

let
  # Want to add a new drive? See README.md for instructions.
  nas_drive_uuids = {
    "/mnt/disk1" = "3d9fbde5-f6ae-49e7-8f13-abe194fbf17a";
    "/mnt/disk2" = "9ce5e827-9e77-4aef-9d22-3b09bc0d512b";
    "/mnt/disk3" = "20a88b0b-3f2e-4579-8f86-a47d7b5b343a";
  };
in
{
  environment.systemPackages = with pkgs; [
    mergerfs
    mergerfs-tools
  ];

  fileSystems = (builtins.mapAttrs (mnt_path: uuid: {
      device = "/dev/disk/by-uuid/${uuid}";
      fsType = "ext4";
      options =
        [ "rw" "user" "auto" ];
    }) nas_drive_uuids) // {
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

  # Set up NFS server.
  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /mnt/media 192.168.1.0/24(rw,sync,insecure,no_root_squash,fsid=root,anonuid=1000,anongid=1000)
  '';
}
