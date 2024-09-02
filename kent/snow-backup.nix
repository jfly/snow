{ config, pkgs, ... }:

let
  identities = import ../shared/identities.nix;
  # Generated with: ssh-keygen -t ed25519 -f key -P "" -C fflam  #<<<
  # Don't forget to update identities.nix if you regenerate this.
  keypair = {
    privateKeyfile = config.age.secrets.snow-backup-ssh-private-key.path;
  };
  snow-backup = pkgs.writeShellApplication {
    name = "snow-backup";
    runtimeInputs = [ pkgs.curl pkgs.rsync pkgs.openssh ];
    text = ''
      set -e

      rsync --exclude "deercam/analysis" -avP --delete --rsh "ssh -i ${keypair.privateKeyfile}" root@fflewddur:/mnt/media/ /mnt/media/

      # Finally, report a successful backup =)
      curl "https://monitoring.snow.jflei.com/api/push/gLRwjziFaf?status=up&msg=OK&ping="
    '';
  };
in
{
  age.secrets.snow-backup-ssh-private-key.rooterEncrypted = ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBqUVg2NnNBcHZCUWxBWGcy
    c052bWlBbkRMYnMzVVErbGtwVCt4emFzeWo0CnpQVDVvejc3bHJBMEY3cXhmSFZW
    TFBSNGFsTVNBcURvM1Q3RkdwQkpyMG8KLS0tIGhkS2RjSXFGdG96YnN3UU04b2Jp
    V0cvU0NBS24vWlU2VWFwWDlRQUFXaVEKTBBDx9ndVJyN595Yp3kB5Cr0kF6v03Qf
    iJm8pYzRbU8S+VSrHMVZ/gM+Tp87UifjSdLOMoZAHBvh+e/ANfFJzDb14it+7CKP
    oRXwQtcGqvqI6oEAACqN2VWSKmptPZ8yNXn3NMpoePa1lAkdqQvm6inUpdma1LkV
    jDt6bKO3Zdkkj9IvDYEFB40D+JvsUO32PA/84Ek9ojdQmdif2YskZYA3hgIynuA4
    zFA1nOh0hsr/6Mj/HGiAhSqorTk0veztpEsnyFHLNEXhaSnRWl9PGknl+pnGsQT7
    HoPe9N4iUiPOlx5sBQ5g1nqclcHNqpIo13MMbhZ+g5tdODp6eP07oLLe6rSr5y9G
    3NofZF55PxnH5eLoyiz5t6yOvY00rGHH1VDAE0w2UKcsR90lGdYRKZLmxsHB8Q+d
    lFq1QxVXk9ULixQQfJ1urzKS2RXlCLzzHyP62GjOw2FIYyLVA9k5VFCc2gpXZ1gO
    DDlYNZ6MdrBNdp1IQZ+CuruZRUjPboWuHTDJVEuuZ+zOhzxX/iqXoYw/aASnkEV8
    msY1i/Jqxay/kY8=
    -----END AGE ENCRYPTED FILE-----
  '';

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
