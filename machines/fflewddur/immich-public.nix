{
  # <<< immich ran on fflewddur until fflewddur started having serious issues >>>
  # <<< currently it's running on fflam. >>>
  # <<< TODO: clean up /var/lib/immich on fflewddur and corresponding postgres db, or move everything back to fflewddur >>>
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
  snow.services.immich-public-proxy.proxyPass = "http://fflam.m:2283";
  # Settings copied from `snow.services.immich.nginxExtraConfig`.
  snow.services.immich-public-proxy.nginxExtraConfig = ''
    client_max_body_size 50000M;
    proxy_read_timeout   600s;
    proxy_send_timeout   600s;
    send_timeout         600s;
  '';
}
