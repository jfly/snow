{
  pkgs,
  config,
  lib,
  ...
}:

{
  services.immich = {
    enable = true;
    port = 2283;

    environment = {
      IMMICH_MACHINE_LEARNING_URL = lib.mkForce "http://localhost:${config.services.immich.machine-learning.environment.IMMICH_PORT}";
    };
    machine-learning.environment = {
      # `cryptpad` uses 3003, urg. How do people handle this sort of stuff in NixOS?
      # Do they use containers?
      IMMICH_PORT = lib.mkForce "3004";
    };
  };

  # This is to make `pgvecto-rs` (which is used by immich) happy. See
  # <https://github.com/NixOS/nixpkgs/blob/982cfd538a70271cdee0ee7ad457633cf1444eec/pkgs/servers/sql/postgresql/ext/pgvecto-rs/default.nix#L95-L100>.
  services.postgresql.package = pkgs.postgresql_16;

  # https://wiki.nixos.org/wiki/Immich#Enabling_Hardware_Accelerated_Video_Transcoding
  systemd.services."immich-server".serviceConfig.PrivateDevices = lib.mkForce false;
  users.users.immich.extraGroups = [
    "video"
    "render"
  ];

  services.data-mesher.settings.host.names = [ "immich" ];
  services.nginx.virtualHosts."immich.mm" = {
    enableACME = true;
    forceSSL = true;

    # https://wiki.nixos.org/wiki/Immich#Using_Immich_behind_Nginx
    locations."/" = {
      proxyPass = "http://[::1]:${toString config.services.immich.port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
      extraConfig = ''
        client_max_body_size 50000M;
        proxy_read_timeout   600s;
        proxy_send_timeout   600s;
        send_timeout         600s;
      '';
    };
  };

  # This is needed because the Immich android app doesn't support custom CAs:
  #  - https://github.com/immich-app/immich/pull/14335
  #  - https://github.com/immich-app/immich/issues/15230
  #  - https://github.com/dart-lang/sdk/issues/50435
  #  - https://github.com/immich-app/immich/pull/5869
  services.nginx.virtualHosts."immich.snow.jflei.com" = {
    # Disable ACME/SSL. This isn't exposed to the outside, it's all proxied via
    # our `k3s` cluster which does HTTPS termination.
    enableACME = false;
    forceSSL = lib.mkForce false;

    # https://wiki.nixos.org/wiki/Immich#Using_Immich_behind_Nginx
    locations."/" = {
      proxyPass = "http://[::1]:${toString config.services.immich.port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
      extraConfig = ''
        client_max_body_size 50000M;
        proxy_read_timeout   600s;
        proxy_send_timeout   600s;
        send_timeout         600s;
      '';
    };
  };

  snow.backup.paths = [ "/var/lib/immich" ];
}
