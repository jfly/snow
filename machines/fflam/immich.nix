{
  pkgs,
  config,
  ...
}:
{
  services.immich = {
    enable = true;
    host = "::"; # <<< TODO: explain immich public >>>
    port = 2283;
    environment = {
      # Enable Prometheus metrics endpoints.
      # <https://docs.immich.app/features/monitoring/#configuration>
      IMMICH_TELEMETRY_INCLUDE = "all";
      IMMICH_API_METRICS_PORT = "2284";
      IMMICH_MICROSERVICES_METRICS_PORT = "2285";
    };
  };

  # This is to make `pgvecto-rs` (which is used by immich) happy. See
  # <https://github.com/NixOS/nixpkgs/blob/982cfd538a70271cdee0ee7ad457633cf1444eec/pkgs/servers/sql/postgresql/ext/pgvecto-rs/default.nix#L95-L100>.
  services.postgresql.package = pkgs.postgresql_16;

  # https://wiki.nixos.org/wiki/Immich#Enabling_Hardware_Accelerated_Video_Transcoding
  services.immich.accelerationDevices = null; # Allow access to all devices.
  users.users.immich.extraGroups = [
    "video"
    "render"
  ];

  # https://wiki.nixos.org/wiki/Immich#Using_Immich_behind_Nginx
  snow.services.immich.proxyPass = "http://[::1]:${toString config.services.immich.port}";
  snow.services.immich.nginxExtraConfig = ''
    client_max_body_size 50000M;
    proxy_read_timeout   600s;
    proxy_send_timeout   600s;
    send_timeout         600s;
  '';

  snow.services.immich-metrics-api.proxyPass = "http://[::1]:${toString config.services.immich.environment.IMMICH_API_METRICS_PORT}";
  snow.services.immich-metrics-microservices.proxyPass = "http://[::1]:${toString config.services.immich.environment.IMMICH_MICROSERVICES_METRICS_PORT}";

  # <<< TODO: explain immich public >>>
  # <<< networking.firewall.allowedTCPPorts = [
  # <<<   config.services.immich.port
  # <<< ];
  networking.firewall.interfaces.${config.snow.subnets.overlay.interface}.allowedTCPPorts = [
    config.services.immich.port
  ];

  snow.backup.postgresql.dbs = [ config.services.immich.database.name ];
}
