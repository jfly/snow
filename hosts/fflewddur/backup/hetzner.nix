{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Generated with: `ssh-keygen -t ed25519 -f key -P "" -C fflewddur-hetzner-backup`.
  # NOTE: the newline at the end of the file is really important for ssh!
  # https://unix.stackexchange.com/questions/577402/ssh-error-while-logging-in-using-private-key-loaded-pubkey-invalid-format-and
  # Copied to hetzner storage box with `ssh-copy-id -s -p 23 -f -i key u438808@u438808.your-storagebox.de`
  keypair = {
    privateKeyfile = config.age.secrets.fflewddur-hetzner-backup-ssh-private-key.path;
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGJUTFU9OcGUIEkPqJ7Zzs74duSEFQ7hnpwlYHoYYgaT fflewddur-hetzner-backup";
  };
  box = {
    user = "u438808";
    host = "u438808.your-storagebox.de";
    port = 23;
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
        --sftp-user ${box.user} \
        --sftp-host ${box.host} \
        --sftp-port ${toString box.port} \
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

  generateStorageBoxUsageMetrics =
    pkgs.writers.writePython3Bin "hetzner-generate-storage-box-usage-metrics" { }
      ''
        import subprocess
        from pathlib import Path

        node_textfile_dir = Path("${config.snow.monitoring.node_textfile_dir}")

        cp = subprocess.run(
            [
                "${lib.getExe pkgs.openssh}",   # noqa: E501
                "${box.user}@${box.host}",
                "-p",
                "${toString box.port}",
                "-i",
                "${keypair.privateKeyfile}",
                "-o",
                "UserKnownHostsFile=${hetznerKnownHosts}",  # noqa: E501
                "df",
                "--block-size=1",  # 1 block = 1 byte
            ],
            text=True,
            check=True,
            stdout=subprocess.PIPE,
        )

        # Output is *almost* a space separated table. Example:
        # Filesystem      1K-blocks      Used Available Use% Mounted on
        # u438808        1073607936 290169472 783438464  28% /home
        header, *data = cp.stdout.splitlines()
        expected_columns = [
            "Filesystem",
            "1B-blocks",
            "Used",
            "Available",
            "Use%",
            "Mounted on",
        ]
        column_count = len(expected_columns)
        columns = header.split(maxsplit=column_count - 1)
        assert (
            columns == expected_columns
        ), f"Expected {expected_columns}, got {columns}"

        for datum in data:
            (
                filesystem,
                total_bytes,
                used_bytes,
                available_bytes,
                used_percentage,
                mountpoint,
            ) = datum.split(maxsplit=column_count)

            metric_file = (
                node_textfile_dir /
                f"hetzner_storage_box_{filesystem}.prom"
            )
            metric_file.write_text(
                f'hetzner_storage_box_avail_bytes{{filesystem="{filesystem}", mountpoint="{mountpoint}"}} {available_bytes}\n'  # noqa: E501
                f'hetzner_storage_box_size_bytes{{filesystem="{filesystem}", mountpoint="{mountpoint}"}} {total_bytes}\n'  # noqa: E501
            )
      '';
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
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBtUk9ONG1ZQjQwaTFyNVVp
    MnI0QnlhTDJXTVZKUllvOVNCbzJ0VndrVkM4Ci82QmszU1Rxb2lDMzl0eWlrVjQ5
    dUVNZGNLTytuTTJYL05hZ1ZGK0JlMVEKLS0tIE1MY2x5aVRVVENQbkxqQzNTbDVk
    TmFncTh6YkhGOG5JZUU5OVpyNmV4WlUKPJ5JV9TC0KU9Qc8gdQV3KogQt6TKewyT
    rqJjkpa0zu5jAq8yToXbZD79LBkrn5+9S/I+RUqUpVzpJIWxV7u6qGRKV13mNpQO
    CdE4+XIv+uu11lgeeZRUBWYL/PMwxlBeKvCd5m/rdrL34V/zvbmKZ+6ynDZM73dM
    N/dNwP37XVbCQv/3h/jnGN6EAa9iv/hAlicBrnX64feWnvcSNggg8xp0fAXzQmdy
    YuC95WeHKkHs9A1iNu11gzZKZhNjQx3kScgLNA1xFDq926MotIx27GSamBl8/84X
    OPBl2Q04gHk/hZDQM85ont4uRml/IZMWG0a89nIxEhUf6Nj0AX7eh7LHf/7DnbVh
    hsuidkOXpu4hhhU4SW5CXJpcgF8CZ3+9txb0kXQjCNDcwhakOOWNBZ+/XGKVHTGN
    FzTUIjYUB5GsjWI6158LAcy4luLt2gDJJmg79/6/OBzkY5GpYXhc15ciQPp+1DL0
    wBbLXifWEeE0sr9fN9Iacn1dF3ByaDS7TZT8Pf4JFu5AKZjDcoP0E70W3PGR/4b9
    WeqrWd+EWrataajeQCc8mGgniW8le6kQdnGcNWDo05B0cxVP5AQ4Lj2SRw==
    -----END AGE ENCRYPTED FILE-----
  '';

  systemd = {
    # Offsite backups.
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

    # Regularly generate metrics about the disk usage of our Hetzner storage
    # box.
    timers.hetzner-generate-storage-box-usage-metrics = {
      description = "Generate Hetzner storage box usage metrics timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "hourly";
        Unit = "hetzner-generate-storage-box-usage-metrics.service";
      };
    };
    services.hetzner-generate-storage-box-usage-metrics = {
      description = "Generate Hetzner storage box usage metrics";
      enable = true;
      script = lib.getExe generateStorageBoxUsageMetrics;
    };
  };
}
