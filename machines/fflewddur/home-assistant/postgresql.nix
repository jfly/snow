# https://wiki.nixos.org/wiki/Home_Assistant#Using_PostgreSQL
{
  services.home-assistant = {
    extraPackages = ps: with ps; [ psycopg2 ];
    config.recorder.db_url = "postgresql://@/hass";
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "hass" ];
    ensureUsers = [
      {
        name = "hass";
        ensureDBOwnership = true;
      }
    ];
  };
}
