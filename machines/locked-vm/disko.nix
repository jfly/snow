{ pkgs, config, ... }:
{
  boot.loader.systemd-boot.enable = true;

  boot.supportedFilesystems = [ "bcachefs" ];

  clan.core.vars.generators.rootfs = {
    prompts."password" = {
      persist = true;
      type = "hidden";
    };
    files."password".neededFor = "partitioning";
  };

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            rootfs = {
              size = "100%";
              content = {
                type = "bcachefs";
                filesystem = "rootfs"; # Refers to `bcachefs_filesystems.rootfs` below.
                label = "isthisnecessary"; # <<<
                extraFormatArgs = [
                  "--discard"
                ];
              };
            };
          };
        };
      };
    };

    bcachefs_filesystems = {
      rootfs = {
        type = "bcachefs_filesystem";
        passwordFile = config.clan.core.vars.generators.rootfs.files.password.path;
        extraFormatArgs = [
          "--metadata_replicas=2"
        ];
        subvolumes = {
          "subvolumes/root" = {
            mountpoint = "/";
            mountOptions = [ "x-systemd.mount-timeout=infinity" ]; # <<<
          };
          "subvolumes/home" = {
            mountpoint = "/home";
          };
          "subvolumes/nix" = {
            mountpoint = "/nix";
          };
        };
      };
    };
  };

  boot.bcachefs.package = pkgs.bcachefs-tools.overrideAttrs (oldAttrs: {
    patches = oldAttrs.patches or [ ] ++ [
      ./bcachefs-mount-timeout.patch
    ];
  });
}
