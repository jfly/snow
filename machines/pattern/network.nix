{
  networking.hostName = "pattern";

  # Let NetworkManager handle everything.
  networking.networkmanager.enable = true;
  networking.useDHCP = false;

  # Disable the firewall. I'm not used to having one, and we're behind a NAT anyways...
  networking.firewall.enable = false;
}
