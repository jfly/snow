{
  networking.hostName = "pattern";

  # Let NetworkManager handle everything.
  networking.networkmanager.enable = true;
  networking.useDHCP = false;
}
