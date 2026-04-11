{ config, lib, ... }:

# Note: the alerts for zrepl failures are over in
# <machines/fflewddur/prometheus/scrapers/zrepl.nix>.

let
  metricsPort = 9811;
in
{
  networking.firewall.interfaces.${config.snow.subnets.overlay.interface}.allowedTCPPorts = [
    metricsPort
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
            type = "local";
            listener_name = "baykup_sink";
            client_identity = "fflewddur"; # <<< TODO: Ok, this is currently a lie, but soon we'll be moving `bay` to fflewddur. >>>
          };
          filesystems = {
            "bay<" = true;
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
          name = "baykup_sink";
          type = "sink";
          root_fs = "baykup/zrepl/sink";
          serve = {
            type = "local";
            listener_name = "baykup_sink";
          };
        }
      ];
    };
  };
}
