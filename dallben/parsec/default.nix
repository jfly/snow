{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    (callPackage ./parsec.nix {})
    (pkgs.writeShellScriptBin "stop_parsec.sh" "pkill parsecd")
  ];

  # Give gurgi ssh access so it can run stop_parsec.sh
  # TODO: lock down permissions so that's the *only* thing it can do.
  users.users.${config.variables.kodiUsername}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPog+FoId+C37SnL1VfwRE11pGzzvxOM0GL0HjOL1Qqf gurgi@snowdon"
  ];
}
