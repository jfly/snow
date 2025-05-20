{
  # nginx virtual hosts are configured in the appropriate places, but this
  # opens up the port so our k8s cluster can proxy to us.
  networking.firewall.allowedTCPPorts = [ 80 ];
}
