{ config, ... }:

{
  networking.useDHCP = true;

  networking.hostName = config.variables.kodiUsername;
  # Disable the firewall. Kodi needs to expose various ports to function, and
  # we're behind a NAT anyways...
  networking.firewall.enable = false;
}
