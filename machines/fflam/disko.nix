{ config, pkgs, ... }:
{
  boot.loader.systemd-boot.enable = true;

  clan.core.vars.generators.rootfs = {
    files."password".neededFor = "partitioning";
    runtimeInputs = with pkgs; [
      coreutils
      xkcdpass
    ];
    script = ''
      xkcdpass --numwords 4 --delimiter - > $out/password
    '';
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
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                passwordFile = config.clan.core.vars.generators.rootfs.files.password.path;
                settings.allowDiscards = true;
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };
    };
  };
}
