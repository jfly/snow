{ pkgs, ... }:

let
  # Generated with: ssh-keygen -t ed25519 -f key -P "" -C fflewddur
  keypair = {
    public = pkgs.writeText ''
      ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIEQMi8YQeO6VJmLY48glkzBg1RLINWkWN7C7DRvgxm0 fflewddur
    '';
    private = pkgs.deage.file ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBvc2xhTndFUXU5dkFYSXF4
      di9NSkFKTVpSTWlXSHAzOWxoMExtQkNKWlNVCnhvQjl1QkZ3dVVwczlyazdqV1VV
      T0tiZDVFUTZmejVWV3RlRmQ4eDMxUncKLS0tIFR4aWFwNEd5QkJScHlXU1VJQmp1
      amFKUVF5cGJiWGVFUXlteGdsS0hQNjgK4faRj41f5TKmaY6Dqxd7FWtqm8jdW8HL
      eI6vQK2h5Gj9aXk6X2xO2nnvkg8xwAvOKxKModX08/bRtIC0G3SwauLsWTGW8pV9
      fDZJZPXwWaJVXKdjeucJRK3NFKExhVduWrS0Z+fzSYQlRgIoB+askmWaHoyPUroL
      h9rotHxgHa1nnTjC47CRgEXKcHLZq1DTCvruqEXSf77qYI9QXJahQ8BQk0h8a6Me
      gMHyoLsbMyrzTeeTSAPxRARkVluaYYqB00DfSzbw365nHKwfiBGygIYPe2SwWa5t
      7P8TZ3DdvUXlX94gjpXYoxWoGmA0/n5h/DcawC3D7qmOCEsf/cJPoeMvJcdK9d71
      QA0DAChvSBLmATyhQlH04w1mIGll7B0W8R/GCrp596wminc0sGvzOma/Oq8I6F0v
      uRO0lvG2rWDR7piCghpVnvku7zlKiCs03M0KNIgXaTq5R8BSv1vXVCALp3JNpCMR
      fuKfzdttn0s4z7mY4CrfNxegDicKWlbe7XbH8ayOe3RqGjupbl64xbj7IJ1nfKbe
      cXd9bQk3gwimfg5/AzgV2uDkxIO6wo0=
      -----END AGE ENCRYPTED FILE-----
    '';
  };
  clark-backup = pkgs.writeShellScriptBin "clark-backup" ''
    set -e
    # Urg, hacking around nix store permissions...
    tmp=$(mktemp)
    function finish {
      rm -f "$tmp"
    }
    trap finish EXIT
    cp "${keypair.private}" "$tmp"
    chmod o-r "$tmp"
    ${pkgs.rsync}/bin/rsync -avP -e "${pkgs.openssh}/bin/ssh -i $tmp" clark@clark:/mnt/media/ /mnt/media/
  '';
in
{
  programs.ssh.knownHosts = {
    "clark" = {
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJgSFJufFHoF0Zw3oTme7zRyogS1nTIIfoQXhk1NWyfu";
    };
  };

  systemd = {
    timers.clark-backup = {
      description = "clark backup timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Unit = "clark-backup.service";
      };
    };
    services.clark-backup = {
      description = "Backup clark";
      enable = true;
      script = "${clark-backup}/bin/clark-backup";
    };
  };

  environment.systemPackages = [
    clark-backup
  ];
}
