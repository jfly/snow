{
  boot.supportedFilesystems.zfs = true;

  # Yikes: "This is enabled by default for backwards compatibility purposes,
  # but it is highly recommended to disable this option, as it bypasses some of
  # the safeguards ZFS uses to protect your ZFS pools."
  boot.zfs.forceImportRoot = false;

  services.zfs.autoScrub = {
    enable = true;
    interval = "monthly";
  };

  services.zfs.autoSnapshot = {
    enable = true;
    flags = "--keep-zero-sized-snapshots --parallel-snapshots --utc";
  };

  # Keep the list of exporters in sync with `scrapeConfigs` in `machines/fflewddur/prometheus/`.
  services.prometheus.exporters.zfs = {
    enable = true;
    openFirewall = true;
  };
}
