{ config, ... }:

{
  # https://www.audiobookshelf.org/docs#linux-install-nix

  services.audiobookshelf = {
    enable = true;
    port = 8001;
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
