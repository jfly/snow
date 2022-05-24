{...}:

{
  networking.hostName = "pattern";
  networking.networkmanager.enable = true;
  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eno0.useDHCP = true;
  networking.interfaces.wlp0s20f3.useDHCP = true;
  # Disable the firewall. I'm not used to having one, and we're behind a NAT anyways...
  networking.firewall.enable = false;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    permitRootLogin = "no";
  };
}
