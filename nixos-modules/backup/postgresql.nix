{ config, lib, ... }:
let
  cfg = config.snow.backup.postgresql;
in
{
  options.snow.backup.postgresql = {
    dbs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = ''
        Postgresql databases to backup.
      '';
      default = [ ];
    };
  };

  config = lib.mkIf (cfg.dbs != [ ]) {
    services.postgresqlBackup = {
      enable = true;
      databases = cfg.dbs;
    };

    snow.backup = {
      paths = [
        config.services.postgresqlBackup.location
      ];

      backupPrepareCommands =
        let
          services = map (dbName: "postgresqlBackup-${dbName}.service") cfg.dbs;
        in
        ''
          echo "Backing up postgresql databases: ${lib.concatStringsSep ", " cfg.dbs}"
          systemctl start ${lib.escapeShellArgs services}
        '';
    };
  };
}
