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
    ### Honor
    # server-config
    vagrant
    gnupg
    openssl
  ];
}
