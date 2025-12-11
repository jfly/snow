{ config, pkgs, ... }:

let
  inherit (config.snow) services;

  device = "//${services.fflewddur.fqdn}/archive";
in
{
  clan.core.vars.generators.samba-archive = {
    prompts.username = {
      description = ''
        Username for ${device} samba share.
      '';
    };
    prompts.password = {
      description = ''
        Password for ${device} samba share.
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
  fileSystems."/mnt/archive" = {
    inherit device;
    fsType = "cifs";
    options = [
      "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,credentials=${
        config.clan.core.vars.generators.samba-archive.files."credentials".path
      }"
    ];
  };
}
