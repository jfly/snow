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

  # TODO: remove once k8s no longer needs this.
  # Set up NFS server.
  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /mnt/media 192.168.28.0/24(rw,sync,insecure,no_root_squash,fsid=root,anonuid=1000,anongid=1000)
  '';
  networking.firewall.allowedTCPPorts = [ 2049 ];

  users.users.archive = {
    isSystemUser = true;
    group = "bay";
  };

  # Set up Samba server (from https://wiki.nixos.org/wiki/Samba)
  services.samba = {
    enable = true;
    openFirewall = true;
    # `samba4Full` is compiled with avahi support, which is required for samba
    # to register mDNS records for auto discovery
    package = pkgs.sambaFull.override {
      # Workaround for <https://github.com/NixOS/nixpkgs/issues/426401>
      enableCephFS = false;
    };
    settings = {
      global = {
        "security" = "user";
        "workgroup" = "WORKGROUP";
        "server string" = config.networking.hostName;
        "netbios name" = config.networking.hostName;
        "use sendfile" = "yes";
        # Note: `localhost` is the IPv6 localhost `::1`.
        # `192.168.28.*` is our trusted home VLAN.
        # `fdd4:aa51:eed9:426:9f99:93::/88` is our VPN.
        "hosts allow" = "127.0.0.1 localhost 192.168.28. fdd4:aa51:eed9:426:9f99:93::/88";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };

      archive = {
        path = "/mnt/bay/archive";
        "valid users" = "jfly rachel";
        browseable = "yes";
        writeable = "yes";
        "force user" = config.users.users.archive.name;
        "guest ok" = "no";
      };

      dangerzone = {
        path = "/mnt/bay/dangerzone";
        "valid users" = "jfly rachel";
        browseable = "yes";
        writeable = "yes";
        "force user" = config.users.users.archive.name;
        "guest ok" = "no";
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
    # Workaround for avahi crash on name conflicts:
    # <https://github.com/avahi/avahi/issues/117#issuecomment-401225716>
    allowInterfaces = [ config.clan.data-mesher.network.interface ];
  };

  # Advertise shares for Windows clients.
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  snow.backup.paths = [ "/mnt/bay/archive" ];
}
