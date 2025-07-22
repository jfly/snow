{ flake, config, ... }:

let
  domain = {
    sld = "syncthing.${config.networking.hostName}";
    fqdn = "${domain.sld}.${config.snow.tld}";
  };
in
{
  imports = [ flake.nixosModules.nginx ];

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;

    # Allow configuration via the UI.
    overrideFolders = false;
    overrideDevices = false;

    settings = {
      # https://docs.syncthing.net/users/faq.html#why-do-i-get-host-check-error-in-the-gui-api
      gui.insecureSkipHostcheck = true;
    };
  };
  systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true"; # Don't create default ~/Sync folder

  services.data-mesher.settings.host.names = [ domain.sld ];
  services.nginx.virtualHosts.${domain.fqdn} = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://${config.services.syncthing.guiAddress}";
    };
  };

  snow.backup.paths = [ config.services.syncthing.dataDir ];
}
