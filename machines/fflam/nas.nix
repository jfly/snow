{
  config,
  pkgs,
  lib,
  ...
}:
{
  boot.supportedFilesystems = [ "bcachefs" ];

  # Set the "immutable" attribute on various mountpoints to ensure that nobody
  # writes to the folders unless something is mounted there.
  # This is a bit tricky to do reliably: we don't want to set the immutable
  # bit on the drive, so we mount the root filesystem with a bind mount so
  # we can access the original (unmounted) `/mnt/*`.
  # We can then reliably set the immutable bit on the original folders.
  systemd.tmpfiles.rules = [
    "d /mnt/rootfs/mnt/rootfs 0755 root root - -"
    "h /mnt/rootfs/mnt/rootfs - - - - +i"

    "d /mnt/rootfs/mnt/bay 0755 root root - -"
    "h /mnt/rootfs/mnt/bay - - - - +i"

    "d /mnt/rootfs/mnt/media 0755 root root - -"
    "h /mnt/rootfs/mnt/media - - - - +i"
  ];

  # It's not obvious, but this mount happens before `systemd-tmpfiles-setup.service` runs.
  fileSystems."/mnt/rootfs" = {
    device = "/";
    options = [
      "bind"
      "private" # This must be a private bind mount to avoid propagating mounts.
    ];
  };

  clan.core.vars.generators.nas = {
    prompts."password" = {
      persist = true;
      type = "hidden";
    };
  };

  # This was inspired by
  # <https://wiki.nixos.org/wiki/Bcachefs#Automatically_mount_encrypted_device_on_boot>.
  systemd.services."mnt-bay" = {
    after = [ "local-fs.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      FILESYSTEM_UUID = "5dc8ec0c-cd70-4549-bd91-adca08356225";
      MOUNT_POINT = "/mnt/bay";
    };
    unitConfig.StartLimitIntervalSec = 0; # Try forever.
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      # Don't allow dependent services to see failures, otherwise those services
      # will get stuck due to a dependency failing. This hides that failure.
      # See <https://github.com/systemd/systemd/pull/27584> for details.
      RestartMode = "direct";
      RestartSec = 5;
      User = "root";
      ExecStart =
        let
          #<<< TODO: explain. see src/commands/mount.rs in bcachefs-tools >>>
          bcachefs-tools = pkgs.bcachefs-tools.overrideAttrs (oldAttrs: {
            postPatch = oldAttrs.postPatch or "" + ''
              substituteInPlace src/commands/mount.rs \
                --replace-fail 'std::process::Command::new("modprobe")' 'std::process::Command::new("${lib.getExe' pkgs.kmod "modprobe"}")'
            '';
          });
        in
        lib.getExe (
          pkgs.writeShellApplication {
            name = "mount";
            text = ''
              # Check if the drive is already mounted.
              if ${lib.getExe' pkgs.util-linux "mountpoint"} --quiet "$MOUNT_POINT"; then
                echo "Drive already mounted at $MOUNT_POINT. Skipping..."
                exit 0
              fi

              # Workaround for <https://github.com/NixOS/nixpkgs/issues/32279>
              ${lib.getExe' pkgs.keyutils "keyctl"} link @u @s

              # Mount the device.
              ${lib.getExe bcachefs-tools} mount \
                --passphrase-file ${config.clan.core.vars.generators.nas.files.password.path} \
                "UUID=$FILESYSTEM_UUID" "$MOUNT_POINT"
            '';
          }
        );
      ExecStop = lib.getExe (
        pkgs.writeShellApplication {
          name = "umount";
          text = ''
            ${lib.getExe pkgs.umount} "$MOUNT_POINT"
          '';
        }
      );
    };
  };

  systemd.services."mnt-media" = {
    after = [ config.systemd.services.mnt-bay.name ];
    requires = [ config.systemd.services.mnt-bay.name ];
    wantedBy = [ "multi-user.target" ];
    # Try forever. Ideally there'd be a systemd-native way to mount the
    # filesystem as soon as all its members are present. Some people
    # handle this by explicitly adding dependencies on the drives
    # that make up the pool, but I want to be able to add/remove
    # drives to the pool without having to redeploy.
    # For more information about this problem, see:
    # - <https://github.com/koverstreet/bcachefs/issues/930>
    # - <https://github.com/systemd/systemd/issues/8234>
    unitConfig.StartLimitIntervalSec = 0;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 5;
      User = "root";
      ExecStart = lib.getExe (
        pkgs.writeShellApplication {
          name = "mount";
          text = ''
            ${lib.getExe pkgs.mount} --bind /mnt/bay/media /mnt/media
          '';
        }
      );
      ExecStop = lib.getExe (
        pkgs.writeShellApplication {
          name = "umount";
          text = ''
            ${lib.getExe pkgs.umount} /mnt/media
          '';
        }
      );
    };
  };
  # <<< DONE >>>
  # sudo mount /dev/disk/by-partuuid/4b8111f7-e28d-435d-9c42-d3fe0b6d8e00 /mnt/disk1
  # sudo rsync -aAXUH --info=progress2 --human-readable --no-inc-recursive /mnt/disk1/ /mnt/bay/
  # sudo umount /mnt/disk1 && sudo rmdir /mnt/disk1/
  # sudo bcachefs device add --rotational /dev/disk/by-uuid/5dc8ec0c-cd70-4549-bd91-adca08356225 /dev/disk/by-partuuid/4b8111f7-e28d-435d-9c42-d3fe0b6d8e00
  #
  # sudo mount /dev/disk/by-partuuid/8e3f78e3-9941-4c6b-8867-be131adf5b87 /mnt/disk4
  # <<< IN PROGRESS >>>
  # NOTE: this will fail as it has 12 TiB on it, but /mnt/bay only has 9.7 TiB of free space.
  # sudo rsync -aAXUH --info=progress2 --human-readable --no-inc-recursive /mnt/disk4/ /mnt/bay/
  # sudo umount /mnt/disk4 && sudo rmdir /mnt/disk4/
  # sudo bcachefs device add --rotational /dev/disk/by-uuid/8e3f78e3-9941-4c6b-8867-be131adf5b87 /dev/disk/by-partuuid/8e3f78e3-9941-4c6b-8867-be131adf5b87
  #
  # <<< TODO >>>: confirm there are no leftover mountpoints: /mnt/disk*

  # Allow fflewddur to push backups here.
  # <<< users.users.root.openssh.authorizedKeys.keys = [
  # <<<   (builtins.readFile ../../vars/shared/fflewddur-fflam-backup-ssh/key.pub/value)
  # <<< ];
  # <<< TODO >>>: confirm that `fflewddur-backup-to-fflam.service` succeeds on fflewddur
}
