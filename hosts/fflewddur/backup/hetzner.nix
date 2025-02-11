{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Generated with: `ssh-keygen -t ed25519 -f key -P "" -C fflewddur-hetzner-backup`
  # Copied to hetzner storage box with `ssh-copy-id -s -p 23 -f -i key u438808@u438808.your-storagebox.de`
  keypair = {
    privateKeyfile = config.age.secrets.fflewddur-hetzner-backup-ssh-private-key.path;
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGJUTFU9OcGUIEkPqJ7Zzs74duSEFQ7hnpwlYHoYYgaT fflewddur-hetzner-backup";
  };
  hetznerKnownHosts = pkgs.writeTextFile {
    name = "hetzner-known-hosts";
    # Generated with `ssh-keyscan -p 23 u438808.your-storagebox.de`
    # Compare with <https://docs.hetzner.com/storage/storage-box/access/access-sftp-scp#ssh-host-keys>
    text = ''
      # u438808.your-storagebox.de:23 SSH-2.0-OpenSSH_9.7 FreeBSD-20240806
      [u438808.your-storagebox.de]:23 ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAGK0po6usux4Qv2d8zKZN1dDvbWjxKkGsx7XwFdSUCnF19Q8psHEUWR7C/LtSQ5crU/g+tQVRBtSgoUcE8T+FWp5wBxKvWG2X9gD+s9/4zRmDeSJR77W6gSA/+hpOZoSE+4KgNdnbYSNtbZH/dN74EG7GLb/gcIpbUUzPNXpfKl7mQitw==
      # u438808.your-storagebox.de:23 SSH-2.0-OpenSSH_9.7 FreeBSD-20240806
      [u438808.your-storagebox.de]:23 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==
      # u438808.your-storagebox.de:23 SSH-2.0-OpenSSH_9.7 FreeBSD-20240806
      [u438808.your-storagebox.de]:23 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs
      # u438808.your-storagebox.de:23 SSH-2.0-OpenSSH_9.7 FreeBSD-20240806
      # u438808.your-storagebox.de:23 SSH-2.0-OpenSSH_9.7 FreeBSD-20240806
    '';
  };
  fflewddur-backup-to-hetzner = pkgs.writeShellApplication {
    name = "fflewddur-backup-to-hetzner";
    runtimeInputs = [
      pkgs.curl
      pkgs.rclone
    ];
    text = ''
      start_time=$(date +%s.%N)

      # From <https://docs.hetzner.com/storage/storage-box/access/access-ssh-rsync-borg>
      # > If you receive md5 checksum errors while you upload larger
      # > directories, you probably have reached the connection limit for your
      # > account [...] To avoid this behaviour, you can add the flag
      # > `--checkers=<count lower 8>` for sftp connections...
      rclone sync \
        --sftp-user u438808 \
        --sftp-host u438808.your-storagebox.de \
        --sftp-port 23 \
        --sftp-key-file ${keypair.privateKeyfile} \
        --sftp-known-hosts-file ${hetznerKnownHosts} \
        --checkers=7 \
        --log-level=INFO \
        /mnt/bay/restic \
        :sftp:./manman

      end_time=$(date +%s.%N)
      duration_seconds=$(echo "$end_time - $start_time" | ${lib.getExe pkgs.bc})

      # Finally, report a successful backup =)
      echo "That backup took $duration_seconds seconds. Reporting success to Prometheus"
      echo 'backup_completion_timestamp_seconds{site="hetzner"}' "$(date +%s)" | ${pkgs.moreutils}/bin/sponge ${config.snow.monitoring.node_textfile_dir}/backup_completion_timestamp_seconds-hetzner.prom
      echo 'backup_duration_seconds{site="hetzner"}' "$duration_seconds" | ${pkgs.moreutils}/bin/sponge ${config.snow.monitoring.node_textfile_dir}/backup_duration_seconds-hetzner.prom
    '';
  };
in
{
  age.secrets.fflewddur-backup-to-hetzner-monitor-api-key = {
    # Create a new monitor on <https://monitoring.snow.jflei.com/>, copy the
    # token from the heartbeat url.
    rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBGKzR3SkI5UlZKMUdLakp2
      QXlZdEowMEszOWFLSm1JRzZtTUpJdllrZzBnCllEQnpHMnlLaU4xaDdHMWd2VzBJ
      T1pTbFRVRERpQUNwanZ0NVpra3ExNG8KLS0tIEdVWW1vNlpYT01GZWtVOVVnV1ND
      NEw3L1JYUlBGMzhuWVdiOGMvWkJKeVEK0qLpmND7duzKB/DvlDwS0ASSJBR/xWny
      RY6k9+e9zBAE0gBq4AL2FXYQ
      -----END AGE ENCRYPTED FILE-----
    '';
  };

  age.secrets.fflewddur-hetzner-backup-ssh-private-key.rooterEncrypted = ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBQc2JaY0ZjRmJ6VnJpU2N6
    cHM0VXE0U3VaVHBRNnNJYm5Pa3JjQm5ZQTNjCk1RU3F0ZU5rMW9zUWd0RWkySUhJ
    OE5pSUdOMkR3R3pLZTY4NVNHZndXY0UKLS0tIFA2a3BmKzd3N2xDSnUwQUtXLzMy
    cCtreFByQjRWM01veFJjRndyR2tEWmcK5BWpzwlvRcnlhfrS1JR4CGvQXF6B30B9
    d18ja6HSwqaz2F1xiQ8YuiTafP270b3P1lxKgIPLNhVxoxebj82xhpyEQr+2ojg5
    b90vmnpzTIDb4Xzcz2cnLp+PhccmRJ0SHgaSLHbkQEo7/BZ8Gx4SZQU1hB2V6sNf
    kKwVvq237TiK/m/NmzlmTujrGfEhBw/f69oNbl9nwfvTuFzpXj/FTbd/xDT1BkHX
    7z+kJIegbcZzanIsiZ/fWcaOK6enbiqCLp/3Xk9BLTaJuql4o0dsxnyCmBB5Cgj9
    97SlaCAktH4Q0jKyYgxCl6q9jSzgvf93AwXGb3A+q441bgKv+3ISjfTNSZXk4yFj
    BLRuypZr/8LerhdpU6gDx2A1iUbsLAcC3Sr7HB4/BlB/BiHeOeKYnCjGBLpzf/e2
    IjfMy/7WE53qAwcxlLfUyTnqc2g1kDjHfjbzI73yYa6/hqQ15cZcduSWYvVgHKq1
    IRcM1kfCg0J7lXsC/PupmLTkeO/+47h9+NLYa+mmGwDl+2sxwahrunWBtEduKDMA
    CCWBOOzk/a9+khh+weVoXP74kU4Qpwbytm8VSgKEW9VyuKNshZPlz3VY
    -----END AGE ENCRYPTED FILE-----
  '';

  systemd = {
    timers.fflewddur-backup-to-hetzner = {
      description = "snow backup timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Unit = "fflewddur-backup-to-hetzner.service";
      };
    };
    services.fflewddur-backup-to-hetzner = {
      description = "snow backup";
      enable = true;
      script = lib.getExe fflewddur-backup-to-hetzner;
    };
  };
}
