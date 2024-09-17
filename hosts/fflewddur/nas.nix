{ config, pkgs, ... }:

let
  # Want to add a new drive? See README.md for instructions.
  nasDriveUuids = {
    "/mnt/disk1" = "3d9fbde5-f6ae-49e7-8f13-abe194fbf17a";
    "/mnt/disk2" = "dac09fb6-d300-4892-b83b-3acef83cc757";
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

  # Set up NFS server.
  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /mnt/media 192.168.1.0/24(rw,sync,insecure,no_root_squash,fsid=root,anonuid=1000,anongid=1000)
  '';

  # Set up Samba server (from https://nixos.wiki/wiki/Samba#Samba_Server)
  services.samba-wsdd.enable = true; # make shares visible for windows 10 clients
  services.samba = {
    enable = true;
    settings = {
      global = {
        "security" = "user";
        "workgroup" = "WORKGROUP";
        "server string" = config.networking.hostName;
        "netbios name" = config.networking.hostName;
        "use sendfile" = "yes";
        # note: localhost is the ipv6 localhost ::1
        "hosts allow" = "192.168.0. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };

      media = {
        path = "/mnt/media";
        browseable = "yes";
        "read only" = "yes";
        "guest ok" = "yes";
      };
    };
  };

  # Enable the Restic REST server.
  services.restic.server = {
    enable = true;
    listenAddress = "8000";
    dataDir = "/mnt/bay/restic";
    # We're not (currently) requiring authentication to speak to the rest
    # server. This allows us to avoid futzing with HTTPS and certificates.
    # However, it does mean that anyone on the network can talk to this server
    # (we don't expose port 8000 to the internet), so to remove the risk of
    # folks deleting backups, we run the server in "append only" mode.
    # From https://github.com/restic/rest-server?tab=readme-ov-file#why-use-rest-server:
    #   > the REST backend has better performance, especially so if you can skip
    #   > additional crypto overhead by using plain HTTP transport
    appendOnly = true;
    extraFlags = [
      # See comment above `appendOnly` for why this is safe.
      "--no-auth"
    ];
  };
}
