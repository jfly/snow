# TODO: upstream to nixpkgs?
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.ntfy-alertmanager;

  conf = pkgs.writeTextFile {
    name = "ntfs-alertmanager.conf";
    text = /* scfg */ ''
      http-address 127.0.0.1:${toString cfg.port}
      log-level debug
      alert-mode single

      labels {
          order "severity"

          severity "error" {
              priority 5
          }

          severity "warning" {
              priority 3
          }

          severity "info" {
              priority 1
          }
      }

      resolved {
          tags "resolved"
          priority 1
      }

      ntfy {
          server ${cfg.ntfy.server}
          topic ${cfg.ntfy.topic}
      }

      # When the alert-mode is set to single, ntfy-alertmanager will cache each single alert
      # to avoid sending recurrences.
      cache {
          # If restarts become annoying, consider setting up valkey instead.
          type memory
          duration 24h
          cleanup-interval 1h
      }
    '';
  };
in
{
  options.services.ntfy-alertmanager = {
    enable = lib.mkEnableOption "ntfy-alertmanager";
    package = lib.mkPackageOption pkgs "ntfy-alertmanager" { };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
    };
    ntfy = {
      server = lib.mkOption {
        type = lib.types.str;
        default = "https://ntfy.sh";
      };
      topic = lib.mkOption {
        type = lib.types.str;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.ntfy-alertmanager = {
      description = "A bridge between ntfy and Alertmanager.";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package} -config ${conf}";
        DynamicUser = true;
        Type = "simple";
        Restart = "on-failure";
        RestartSec = 3;
      };
    };
  };
}
