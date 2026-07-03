{ config, lib, ... }:

# Note: the alerts for zrepl failures are over in
# <machines/fflewddur/prometheus/scrapers/zrepl.nix>.

let
  metricsPort = 9811;
  sinkPort = 3912;
  doliIp = builtins.readFile ../../../vars/shared/zerotier-ip-doli-manman/ip/value;
in
{
  networking.firewall.interfaces.${config.snow.subnets.overlay.interface}.allowedTCPPorts = [
    metricsPort
    sinkPort
  ];

  services.zrepl = {
    enable = true;
    settings = {
      global = {
        logging = [
          {
            type = "syslog";
            level = "info";
            format = "human";
          }
        ];

        # https://zrepl.github.io/configuration/monitoring.html
        monitoring = [
          {
            type = "prometheus";
            listen = ":${toString metricsPort}";
          }
        ];
      };

      jobs = [
        {
          name = "bay_to_baykup";
          type = "push";
          connect = {
            type = "tcp";
            address = "fflam.m:3912";
          };
          filesystems = {
            "bay<" = true;
            # Do *not* take snapshots of datasets that were sent here, it'll
            # break replication (see
            # <https://github.com/zrepl/zrepl/issues/248>).
            # Ideally we *would* still send those datasets somewhere else for
            # redundancy. I suspect that would require a separate job. This is
            # too difficult to get right :(
            "bay/zrepl<" = false;
          };

          # Note that the snapshots zrepl creates are in addition to whatever
          # snapshots zfs-auto-snapshotter creates. Perhaps it would be better
          # to let zrepl handle all snapshots? However, there are some places
          # where I'd like to have snapshots without doing zrepl backups (for
          # example, we use restic backups in a lot of places, and I'm pretty
          # happy with that). :shrug:
          snapshotting = {
            type = "periodic";
            interval = "30m";
            prefix = "zrepl_";
          };
          pruning = {
            keep_sender = [
              # Give snapshots a chance to get backed up before they are
              # pruned.
              { type = "not_replicated"; }

              # Keep all snapshots that were not created by `zrepl`.
              {
                type = "regex";
                negate = true;
                regex = "^zrepl_.*";
              }

              # Keep an increasingly sparse history of snapshots created by
              # `zrepl`.
              {
                type = "grid";
                regex = "^zrepl_.*";
                grid = lib.concatStringsSep " | " [
                  "1x1h(keep=all)"
                  "24x1h"
                  "35x1d"
                  "6x30d"
                ];
              }
            ];
            keep_receiver = [
              # Keep all snapshots that were not created by `zrepl`.
              {
                type = "regex";
                negate = true;
                regex = "^zrepl_.*";
              }

              # Keep an increasingly sparse history of snapshots created by
              # `zrepl`.
              {
                type = "grid";
                regex = "^zrepl_.*";
                grid = lib.concatStringsSep " | " [
                  "1x1h(keep=all)"
                  "24x1h"
                  "35x1d"
                  "6x30d"
                ];
              }
            ];
          };
        }
        {
          name = "bay_sink";
          type = "sink";
          root_fs = "bay/zrepl/sink";
          recv.placeholder.encryption = "inherit"; # https://zrepl.github.io/configuration/sendrecvoptions.html#placeholders
          serve = {
            type = "tcp";
            listen = ":${toString sinkPort}";
            clients = {
              ${doliIp} = "doli";
            };
          };
        }
      ];
    };
  };
}
