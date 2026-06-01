# doli OOMs if it tries to use restic to back up /var/lib.
# Instead, doli uses zrepl to send its /var/lib to us. We mount it in
# /var/backup, which gets backed up to restic on this machine, which has enough
# ram to do the job.
let
  destination = "/var/backup/doli-var-lib";
in
{
  snow.backup.extraPaths = [ destination ];

  fileSystems = {
    ${destination} = {
      device = "bay/zrepl/sink/doli/zroot/root/var/lib";
      fsType = "zfs";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${destination} 0700 root - - -"
  ];
}
