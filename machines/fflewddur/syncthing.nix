{ config, ... }:
{
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

  services.nginx = {
    enable = true;
    virtualHosts."syncthing.snow.jflei.com" = {
      locations."/" = {
        proxyPass = "http://${config.services.syncthing.guiAddress}";
      };
    };
  };

  snow.backup.paths = [ config.services.syncthing.dataDir ];
}
