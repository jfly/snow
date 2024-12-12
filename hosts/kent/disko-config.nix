{
  # TODO: recreate this machine with `disko`. Remove `filesystems.*` options.
  # ```nix
  # imports = [ inputs.disko.nixosModules.disko ];
  # disko.devices = {
  #   disk.main = {
  #     device = "/dev/nvme0n1";
  #     type = "disk";
  #     content = {
  #       type = "gpt";
  #       partitions = {
  #         esp = {
  #           name = "ESP";
  #           size = "512M";
  #           type = "EF00";
  #           content = {
  #             type = "filesystem";
  #             format = "vfat";
  #             mountpoint = "/boot";
  #           };
  #         };
  #         root = {
  #           name = "root";
  #           size = "100%";
  #           content = {
  #             type = "filesystem";
  #             format = "ext4";
  #             mountpoint = "/";
  #           };
  #         };
  #       };
  #     };
  #   };
  # };
  # ```

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/87dff6a3-f022-48ec-9819-1ec7b01057d7";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/4E22-7385";
    fsType = "vfat";
  };

  boot.loader.systemd-boot.enable = true;
}
