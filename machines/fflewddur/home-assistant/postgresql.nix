let
  dbName = "hass";
in
{
  # https://wiki.nixos.org/wiki/Home_Assistant#Using_PostgreSQL
  services.home-assistant = {
    extraPackages = ps: with ps; [ psycopg2 ];
    config.recorder.db_url = "postgresql://@/${dbName}";
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ dbName ];
    ensureUsers = [
      {
        name = dbName;
        ensureDBOwnership = true;
      }
    ];
  };

  snow.backup.postgresql.dbs = [ dbName ];
}
