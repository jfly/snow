{
  flake,
  config,
  ...
}:
{
  imports = [ flake.nixosModules.zfs ];

  boot.loader.systemd-boot.enable = true;

  # Keep only a finite number of boot configurations. This prevents /boot from
  # filling up.
  # https://nixos.wiki/wiki/Bootloader#Limiting_amount_of_entries_with_grub_or_systemd-boot
  boot.loader.systemd-boot.configurationLimit = 100;
  boot.loader.efi.canTouchEfiVariables = true;

  # nixos doesn't clear out /tmp on each boot. I'm used to it being a tmpfs
  # (`boot.tmp.useTmpfs = true`), but nix-shell uses it, and it needs a *lot*
  # of space, and I'm not sure I want to allocate that much ram?
  boot.tmp.cleanOnBoot = true;

  boot.initrd.clevis = {
    enable = true;
    useTang = true;
    devices."zroot/root".secretFile = config.clan.core.vars.generators.rootfs-jwe.files.jwe.path;
  };

  clan.core.vars.generators.rootfs = {
    prompts."password" = {
      persist = true;
      type = "hidden";
    };
    files."password".neededFor = "partitioning";
  };

  clan.core.vars.generators.rootfs-jwe = {
    prompts.jwe = {
      persist = true;
      description = ''
        Encrypt a JWE for the root filesystem:

          clan vars get locked-vm rootfs/password | tr -d '\n' | nix run nixpkgs#clevis encrypt tang '{"url": "http://tang.ec"}'
      '';
    };
    files."jwe".neededFor = "activation"; # Used to generate the initrd during system activation.
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
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
    };

    zpool.zroot = {
      type = "zpool";
      rootFsOptions = {
        mountpoint = "none";
        acltype = "posixacl";
        xattr = "sa";
      };
      options.ashift = "12";

      # We have `keylocation` set for initial bootstrapping so we can provision
      # the machine, but after that, someone needs to enter the passphrase for
      # the machine to boot.
      postCreateHook = "zfs set keylocation=prompt zroot/root";

      datasets = {
        # Some folks recommend avoiding using using the root filesystem
        # entirely. See
        # <https://www.reddit.com/r/zfs/comments/tl0r0s/recommended_not_to_use_top_level_dataset/>.
        # This pattern is copied from disko's examples, which seem to do
        # exactly that: use a `zroot/root` "root" dataset rather than the true
        # root dataset (`zroot`). See
        # <https://github.com/nix-community/disko/blob/4707eec8d1d2db5182ea06ed48c820a86a42dc13/example/zfs-encrypted-root.nix#L43-L53>.
        "root" = {
          type = "zfs_fs";
          options = {
            mountpoint = "legacy";
            encryption = "aes-256-gcm";
            keyformat = "passphrase";
            # Note that we only want a file for initial provisioning.
            # Afterwards, it should be "prompt". See the `postCreateHook` above
            # for details.
            keylocation = "file://${config.clan.core.vars.generators.rootfs.files.password.path}";
          };
          mountpoint = "/";
        };
        "root/nix" = {
          type = "zfs_fs";
          mountpoint = "/nix";
          options = {
            mountpoint = "legacy";
            "com.sun:auto-snapshot" = "false";
          };
        };
        "root/home" = {
          type = "zfs_fs";
          mountpoint = "/home";
          options.mountpoint = "legacy";
        };
      };
    };
  };
}
