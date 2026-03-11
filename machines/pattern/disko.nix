{ flake, ... }:
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

  swapDevices = [
    {
      device = "/swapfile";
      size = 2048;
    }
  ];

  # TODO: reformat + switch to ZFS!
  # disko.devices = {
  #   disk = {
  #     main = {
  #       type = "disk";
  #       content = {
  #         type = "gpt";
  #         partitions = {
  #           ESP = {
  #             size = "500M";
  #             type = "EF00";
  #             content = {
  #               type = "filesystem";
  #               format = "vfat";
  #               mountpoint = "/boot";
  #               mountOptions = [ "umask=0077" ];
  #             };
  #           };
  #           zfs = {
  #             size = "100%";
  #             content = {
  #               type = "zfs";
  #               pool = "zroot";
  #             };
  #           };
  #         };
  #       };
  #     };
  #   };

  #   zpool.zroot = {
  #     type = "zpool";
  #     rootFsOptions = {
  #       mountpoint = "none";
  #       acltype = "posixacl";
  #       xattr = "sa";
  #       "com.sun:auto-snapshot" = "true";
  #     };
  #     options.ashift = "12";

  #     datasets = {
  #       # Some folks recommend avoiding using using the root filesystem
  #       # entirely. See
  #       # <https://www.reddit.com/r/zfs/comments/tl0r0s/recommended_not_to_use_top_level_dataset/>.
  #       # This pattern is copied from disko's examples, which seem to do
  #       # exactly that: use a `zroot/root` "root" dataset rather than the true
  #       # root dataset (`zroot`). See
  #       # <https://github.com/nix-community/disko/blob/4707eec8d1d2db5182ea06ed48c820a86a42dc13/example/zfs-encrypted-root.nix#L43-L53>.
  #       "root" = {
  #         type = "zfs_fs";
  #         options = {
  #           mountpoint = "legacy";
  #           encryption = "aes-256-gcm";
  #           keyformat = "passphrase";
  #           keylocation = "prompt";
  #         };
  #         mountpoint = "/";
  #       };
  #       "root/nix" = {
  #         type = "zfs_fs";
  #         mountpoint = "/nix";
  #         options = {
  #           mountpoint = "legacy";
  #           "com.sun:auto-snapshot" = "false";
  #         };
  #       };
  #       "root/home" = {
  #         type = "zfs_fs";
  #         mountpoint = "/home";
  #         options.mountpoint = "legacy";
  #       };
  #       # TODO: is swap on ZFS a bad idea? <https://github.com/openzfs/zfs/issues/7734>
  #       #       I asked @mic92, and he says "when I need swap I mostly use
  #       #       zswap or have a normal linux swap partition (or encrypted swap
  #       #       partition)"
  #       "root/swap" = {
  #         type = "zfs_volume";
  #         size = "16GiB";
  #         content = {
  #           type = "swap";
  #         };

  #         # From <https://wiki.archlinux.org/title/ZFS#Swap_volume>
  #         options = {
  #           volblocksize = "4096"; # `getconf PAGESIZE` on x86 defaults to 4k
  #           compression = "zle";
  #           logbias = "throughput";
  #           sync = "always";
  #           primarycache = "metadata";
  #           secondarycache = "none";
  #           "com.sun:auto-snapshot" = "false";
  #         };
  #       };
  #     };
  #   };
  # };
}
