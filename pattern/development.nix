{ config, pkgs, ... }:

{
  # Enable docker for the main user.
  virtualisation.docker.enable = true;
  users.users.${config.snow.user.name}.extraGroups = [ "docker" ];

  # Set up ssh agent
  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
    extraConfig = ''
      AddKeysToAgent yes
    '';
  };
  environment.variables.SSH_ASKPASS_REQUIRE = "prefer";

  # Enable gpg agent
  programs.gnupg.agent.enable = true;

  environment.systemPackages = with pkgs; [
    ### Network
    curl
    wget
    whois
    netcat
    traceroute
    dnsutils # Provides nslookup
    sipcalc # an advanced console based ip subnet calculator

    ### Honor
    # server-config
    (vagrant.override {
      # I'm having trouble installing the vagrant-aws plugins with this setting enabled.
      withLibvirt = false;
    })
    gnupg
    openssl
    amazon-ecr-credential-helper
  ];
}
