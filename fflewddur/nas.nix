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
        "use_ino"
        "noforget"
        "cache.files=partial"
        "dropcacheonclose=true"
        "allow_other"
        "category.create=mfs"
        "posix_acl=true"
      ];
    };
  };
}
