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

  # https://wiki.nixos.org/wiki/Immich#Using_Immich_behind_Nginx
  snow.services.immich.proxyPass = "http://[::1]:${toString config.services.immich.port}";
  snow.services.immich.nginxExtraConfig = ''
    client_max_body_size 50000M;
    proxy_read_timeout   600s;
    proxy_send_timeout   600s;
    send_timeout         600s;
  '';

  snow.backup.postgresql.dbs = [ config.services.immich.database.name ];

  # Immich Public Proxy
  # Disabled so family can upload vacation pictures.
  # TODO: decide how to handle this.
  # services.immich-public-proxy =
  #   let
  #     inherit (config.snow) services;
  #   in
  #   {
  #     enable = true;
  #     port = 2284;
  #     immichUrl = services.immich.baseUrl;
  #     settings.ipp = {
  #       showMetadata.description = true;
  #       showGalleryTitle = true;
  #       allowDownloadAll = 1; # "follow Immich setting per share"
  #     };
  #   };
  # snow.services.immich-public-proxy.proxyPass = "http://[::1]:${toString config.services.immich-public-proxy.port}";

  # Expose immich directly (as opposed to immich public proxy, see above).
  snow.services.immich-public-proxy.proxyPass = "http://[::1]:${toString config.services.immich.port}";
  snow.services.immich-public-proxy.nginxExtraConfig = ''
    client_max_body_size 50000M;
    proxy_read_timeout   600s;
    proxy_send_timeout   600s;
    send_timeout         600s;
  '';
}
