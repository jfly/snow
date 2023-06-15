{ config, pkgs, myParsec, lib, ... }:

{
  environment.systemPackages = [
    myParsec
  ];

  # Give gurgi ssh access so it can run stop_parsec.sh
  # TODO: lock down permissions so that's the *only* thing it can do.
  users.users.gurgi = {
    isNormalUser = true;
    extraGroups = [
      "wheel" # Enable `sudo` for the user.
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPog+FoId+C37SnL1VfwRE11pGzzvxOM0GL0HjOL1Qqf gurgi@snowdon"
    ];
  };
}
