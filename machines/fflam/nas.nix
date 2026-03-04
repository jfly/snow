{
  flake,
  ...
}:
{
  imports = [
    flake.nixosModules.zfs
  ];

  clan.core.vars.generators.nas = {
    prompts."password" = {
      persist = true;
      type = "hidden";
    };
  };

  # Mount various ZFS datasets. Note that `/mnt/bay` is *not* a parent dataset,
  # so any data in there will land on the rootfs. Don't put anything there! I
  # wonder if we could make it immutable somehow...
  fileSystems."/mnt/bay/archive" = {
    device = "baykup/archive";
    fsType = "zfs";
    options = [
      # Don't block boot if we cannot mount this.
      "nofail"
      # But also do not allow anyone to write to the rootfs, even if the mount
      # fails (this will instead trigger another mount attempt).
      "x-systemd.automount"
    ];
  };
  fileSystems."/mnt/bay/media" = {
    device = "baykup/media";
    fsType = "zfs";
    options = [
      "nofail"
      "x-systemd.automount"
    ];
  };
  fileSystems."/mnt/bay/restic" = {
    device = "baykup/restic";
    fsType = "zfs";
    options = [
      "nofail"
      "x-systemd.automount"
    ];
  };

  # Make media accessible at `/mnt/media`. This is partially
  # historical, but also kind of a nice abstraction.
  fileSystems."/mnt/media" = {
    device = "/mnt/bay/media";
    fsType = "none";
    options = [
      "bind"
      "nofail"
      "x-systemd.automount"
    ];
  };

  # Allow fflewddur to push backups here.
  users.users.root.openssh.authorizedKeys.keys = [
    (builtins.readFile ../../vars/shared/fflewddur-fflam-backup-ssh/key.pub/value)
  ];
}
