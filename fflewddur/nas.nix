{ config, pkgs, ... }:

let
  # Want to add a new drive? See README.md for instructions.
  nas_drive_uuids = {
    "/mnt/disk1" = "3d9fbde5-f6ae-49e7-8f13-abe194fbf17a";
    "/mnt/disk2" = "dac09fb6-d300-4892-b83b-3acef83cc757";
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
        # From https://github.com/trapexit/mergerfs#basic-setup "You don't need mmap"
        "allow_other"
        "use_ino"
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
  };

  # Set up NFS server.
  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /mnt/media 192.168.1.0/24(rw,sync,insecure,no_root_squash,fsid=root,anonuid=1000,anongid=1000)
  '';

  # Set up Samba server (from https://nixos.wiki/wiki/Samba#Samba_Server)
  services.samba-wsdd.enable = true; # make shares visible for windows 10 clients
  services.samba = {
    enable = true;
    securityType = "user";
    extraConfig = ''
      workgroup = WORKGROUP
      server string = fflewddur
      netbios name = fflewddur
      security = user
      use sendfile = yes
      # note: localhost is the ipv6 localhost ::1
      hosts allow = 192.168.0. 127.0.0.1 localhost
      hosts deny = 0.0.0.0/0
      guest account = nobody
      map to guest = bad user
    '';
    shares = {
      media = {
        path = "/mnt/media";
        browseable = "yes";
        "read only" = "yes";
        "guest ok" = "yes";
      };
    };
  };
}
