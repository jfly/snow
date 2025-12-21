{ pkgs, config, ... }:
{
  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    group = "media";
    settings = {
      blocklist-enabled = 0;
      download-dir = "/mnt/media/torrents";
      download-limit = 100;
      download-limit-enabled = 0;
      incomplete-dir = "/mnt/media/torrents/incomplete";
      encryption = 1;
      idle-seeding-limit = 300;
      idle-seeding-limit-enabled = true;
      max-peers-global = 200;
      peer-port = 61207;
      pex-enabled = 1;
      port-forwarding-enabled = 0;
      ratio-limit = 2;
      ratio-limit-enabled = true;
      rpc-authentication-required = 0;
      rpc-password = "transmission";
      rpc-port = 9091;
      rpc-bind-address = "0.0.0.0";
      rpc-username = "transmission";
      rpc-host-whitelist = "*";
      rpc-host-whitelist-enabled = "false";
      rpc-whitelist = "*";
      rpc-whitelist-enabled = "false";
      upload-limit = 100;
      upload-limit-enabled = 0;
      umask = 2;
    };
  };

  systemd.services.transmission = {
    vpnConfinement = {
      enable = true;
      vpnNamespace = "wg";
    };
  };

  vpnNamespaces.wg.portMappings = [
    {
      from = config.services.transmission.settings.rpc-port;
      to = config.services.transmission.settings.rpc-port;
      protocol = "tcp";
    }
  ];

  snow.services.torrents.proxyPass = "http://${config.vpnNamespaces.wg.namespaceAddress}:${toString config.services.transmission.settings.rpc-port}";

  snow.backup.paths = [
    config.services.transmission.home
  ];
}
