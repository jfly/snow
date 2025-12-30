{
  config,
  pkgs,
  lib,
  ...
}:

let
  keypair = {
    privateKeyfile = config.clan.core.vars.generators.fflewddur-hetzner-backup-ssh.files."key".path;
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
      echo 'backup_completion_timestamp_seconds{site="hetzner"}' "$(date +%s)" | ${pkgs.moreutils}/bin/sponge ${config.snow.monitoring.nodeTextfileDir}/backup_completion_timestamp_seconds-hetzner.prom
      echo 'backup_duration_seconds{site="hetzner"}' "$duration_seconds" | ${pkgs.moreutils}/bin/sponge ${config.snow.monitoring.nodeTextfileDir}/backup_duration_seconds-hetzner.prom
    '';
  };

  generateStorageBoxUsageMetrics =
    pkgs.writers.writePython3Bin "hetzner-generate-storage-box-usage-metrics" { }
      ''
        import subprocess
        from pathlib import Path

        node_textfile_dir = Path("${config.snow.monitoring.nodeTextfileDir}")

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
  # Once generated, copy to hetzner storage box with something like:
  # ```
  # cp vars/per-machine/fflewddur/fflewddur-hetzner-backup-ssh/key.pub/value /tmp/key.pub
  # ssh-copy-id -s -p 23 -f -i /tmp/key.pub u438808@u438808.your-storagebox.de
  # ```
  clan.core.vars.generators.fflewddur-hetzner-backup-ssh = {
    files."key" = { };
    files."key.pub".secret = false;
    runtimeInputs = [ pkgs.openssh ];
    script = ''
      ssh-keygen -t ed25519 -f $out/key -P "" -C fflewddur-hetzner-backup
    '';
  };

  systemd = {
    # Offsite backups.
    timers.fflewddur-backup-to-hetzner = {
      description = "fflewddur -> hetzner backup timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Unit = "fflewddur-backup-to-hetzner.service";
      };
    };
    services.fflewddur-backup-to-hetzner = {
      description = "fflewddur -> hetzner backup";
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
