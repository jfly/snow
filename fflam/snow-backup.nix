{ config, pkgs, ... }:

let
  # Generated with: ssh-keygen -t ed25519 -f key -P "" -C fflam
  keypair = {
    # TODO: actually share this value with fflewddur/configuration.nix
    public = pkgs.writeText ''
      ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHxw+hsi7OFBP9tN1S/8PErm/AHWxcyJXC2k6q+96jqa fflam
    '';
    privateKeyfile = config.age.secrets.snow-backup-ssh-private-key.path;
  };
  snow-backup = pkgs.writeShellApplication {
    name = "snow-backup";
    runtimeInputs = [ pkgs.curl pkgs.rsync pkgs.openssh ];
    text = ''
      set -e

      rsync --exclude "deercam/analysis" -avP --delete -e "ssh -i ${keypair.privateKeyfile}" root@fflewddur:/mnt/media/ /mnt/media/

      # Finally, report a successful backup =)
      curl "https://monitoring.snow.jflei.com/api/push/gLRwjziFaf?status=up&msg=OK&ping="
    '';
  };
in
{
  programs.ssh.knownHosts = {
    "fflewddur" = {
      # Obtained with `ssh-keyscan fflewddur`
      # TODO: actually share this with fflewddur's config.
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBu1H1RFGjmzpUncYWUGwCDcQPVfgAxH4S2yYPt46a/5";
    };
  };

  systemd = {
    timers.snow-backup = {
      description = "snow backup timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Unit = "snow-backup.service";
      };
    };
    services.snow-backup = {
      description = "snow backup";
      enable = true;
      script = "${snow-backup}/bin/snow-backup";
    };
  };

  environment.systemPackages = [
    snow-backup
  ];
}
