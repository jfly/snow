{ config, ... }:

{
  imports = [
    # This is a hacky workaround for <https://art19.zendesk.com/agent/tickets/40952>
    # tl;dr: art19 seems to have corrupted versions of some feeds, including
    # "Hello From the Magic Tavern". This isn't obvious to spot: they're using
    # Fastly as a CDN, so depending on where the request comes from, you may or
    # may not get a corrupted copy.
    # By pure luck, I discovered that proxying through `siftrss.com` seems to
    # work, presumably because of where their datacenter is located.
    {
      services.data-mesher.settings.host.names = [ "podhacks" ];
      services.nginx.virtualHosts."podhacks.mm" = {
        enableACME = true;
        forceSSL = true;

        locations."/hello-from-the-magic-tavern" = {
          # I created this url by going to https://www.siftrss.com/ and entering the following:
          # https://rss.art19.com/hello-from-magic-tavern
          # "I want to *exclude* items where the *description* *does not exist*"
          proxyPass = "https://www.siftrss.com/f/KYRgY8Nvz0";
          # Disable `recommendedProxySettings` to avoid this Host header:
          # https://github.com/NixOS/nixpkgs/blob/d3d2d80a2191a73d1e86456a751b83aa13085d7d/nixos/modules/services/web-servers/nginx/default.nix#L108
          # This is because we need the receiving end to know where to forward the request.
          recommendedProxySettings = false;
          extraConfig = ''
            proxy_set_header Host $proxy_host;
          '';
        };
      };
    }
  ];

  # https://www.audiobookshelf.org/docs#linux-install-nix
  services.audiobookshelf = {
    enable = true;
    port = 8001;
  };

  # From https://www.audiobookshelf.org/guides/podcasts/:
  # > NOTE: By default, ABS will not allow you to add a podcast that is hosted
  # > via a local IP address. This is a mitigation to potential server-side
  # > request forgery attacks (SSRF). In rare cases where you are self-hosting a
  # > podcast, you might need to disable this filter to add it. To do so, set the
  # > environment variable DISABLE_SSRF_REQUEST_FILTER=1 on the ABS server.
  systemd.services.audiobookshelf.environment = {
    DISABLE_SSRF_REQUEST_FILTER = "1";
  };

  users.users.audiobookshelf.extraGroups = [ "media" ];

  services.data-mesher.settings.host.names = [ "audiobookshelf" ];
  services.nginx.virtualHosts."audiobookshelf.mm" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${builtins.toString config.services.audiobookshelf.port}";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_redirect http:// $scheme://;
      '';
    };
  };

  snow.backup.paths = [ "/var/lib/${config.services.audiobookshelf.dataDir}" ];
}
