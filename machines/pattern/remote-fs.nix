{ config, pkgs, ... }:

let
  inherit (config.snow) services;

  sambaHost = "//${services.fflewddur.fqdn}";
in
{
  clan.core.vars.generators.samba-bay = {
    prompts.username = {
      description = ''
        Username for ${sambaHost} samba host.
      '';
    };
    prompts.password = {
      description = ''
        Password for ${sambaHost} samba host.
      '';
      type = "hidden";
    };
    files.credentials = { };
    script = ''
      echo "username=$(< $prompts/username)" >> $out/credentials
      echo "password=$(< $prompts/password)" >> $out/credentials
    '';
  };

  # https://wiki.nixos.org/wiki/Samba#Samba_Client
  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."/mnt/bay/archive" = {
    device = "${sambaHost}/archive";
    fsType = "cifs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
      "gid=${toString config.users.groups.bay.gid}"
      "forcegid"
      "credentials=${config.clan.core.vars.generators.samba-bay.files."credentials".path}"
    ];
  };

  fileSystems."/mnt/bay/media" = {
    device = "${sambaHost}/media";
    fsType = "cifs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
      "gid=${toString config.users.groups.media.gid}"
      "forcegid"
      "file_mode=0660" # rw for user and group.
      "dir_mode=0770" # rwx for user and group.
      "credentials=${config.clan.core.vars.generators.samba-bay.files."credentials".path}"
    ];
  };
}
