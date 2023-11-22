{ config, pkgs, ... }:

let
  identities = import ../shared/identities.nix;
  # Generated with: ssh-keygen -t ed25519 -f key -P "" -C fflam
  # Don't forget to update identities.nix if you regenerate this.
  keypair = {
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
      publicKey = identities.fflewddur;
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
