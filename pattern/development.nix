{ config, pkgs, ... }:

{
  # Enable docker for the main user.
  virtualisation.docker.enable = true;
  users.users.${config.snow.user.name}.extraGroups = [ "docker" ];

  environment.systemPackages = with pkgs; [
    ### Honor
    # server-config
    vagrant
    gnupg
    openssl
  ];
}
