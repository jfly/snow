{ pkgs, ... }:

let
  # Generated with: ssh-keygen -t ed25519 -f key -P "" -C fflam
  keypair = {
    public = pkgs.writeText ''
      ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHxw+hsi7OFBP9tN1S/8PErm/AHWxcyJXC2k6q+96jqa fflam
    '';
    private = pkgs.deage.storeFile {
      name = "private-key";
      encrypted = ''
        -----BEGIN AGE ENCRYPTED FILE-----
        YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBENFM1ZFQ3LzlFQVVkenhN
        anY3Qk01c3dlNGxFN2pOazFHRnJvTmpQSUJjCmZ1K3N3VG04TW8wdm9xSkpMb1ox
        VW1MV2prNTdFcjA0L24zVko1TXZJd3MKLS0tIEVlLzNjSkQxREF0NHBiMm1wR3M5
        a3BvdWlYQlU5RzVWVGVYUWp1MWZCQjQK6FELnwtr1cXbDC06KKgXQQQ3pzzL+8xC
        gmiauVNB9MN9P3c6uzWHK0gBg71i6zE35apEykcXLJWIsKnP3BhSNEgug5r5mRdh
        ALIArI6JcrrUbTQUzTC0H9ABOPcdhIGgQUjorRzWmbGInuk3Cran3CQM+jaJNWO7
        BIcGDMK0UMFwHKgANyo6NEeutoBOvnFG9NkuxJQDb2pWLoQ52/o2hOPc609lZTRC
        GqQ/su6TyQJ1JkBztYuFgEKzalRcVZZ7XhFVPY/ari0ZwtTC+Cp12A6/eHs/VDjQ
        0MdFmBNaAQJD/utDn9oFp12+NonQrL+8UhhITCGbUZ+8NGy0GRpGvQ9PxUGh7l5d
        XilYebRl6qbLsJ6/Mm1YwqX2HJOGhjI5P5ng5Zax47F5xAecb6FRbYLQT6ogMDZJ
        DPr1jzf9u0Az4bADetSI9O9U0a6huYMhr4KDFQp8JpRmp6j/7RHM5+68RtjzIa15
        HbpPaJfBXON0+5KUQMDJ9g84ivNjxpCmx+spMLLHCCH2xxFhfEXzmGbHQ7E3ads2
        X4hd6wDwZt7CT/s=
        -----END AGE ENCRYPTED FILE-----
      '';
    };
  };
  snow-backup = pkgs.writeShellScriptBin "snow-backup" ''
    set -e
    # Urg, hacking around nix store permissions...
    tmp=$(mktemp)
    function finish {
      rm -f "$tmp"
    }
    trap finish EXIT
    cp "${keypair.private}" "$tmp"
    chmod o-r "$tmp"
    ${pkgs.rsync}/bin/rsync --exclude "deercam/analysis" -avP --delete -e "${pkgs.openssh}/bin/ssh -i $tmp" root@fflewddur:/mnt/media/ /mnt/media/

    # Finally, report a successful backup =)
    curl "https://monitoring.clark.snowdon.jflei.com/api/push/gLRwjziFaf?status=up&msg=OK&ping="
  '';
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
