{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    (callPackage (import (builtins.fetchTarball {
      name = "parsec-gaming-nix";
      url = "https://github.com/DarthPJB/parsec-gaming-nix/archive/354e8313bf5574cbc16133ee0e7d6845c858bc01.tar.gz";
      # Hash obtained using `nix-prefetch-url --unpack <url>`
      sha256 = "0wnvl27wbhfza2svnqi8daxb98729wwn97gas5jwfz7niv9rgbah";
    })) {})
    (pkgs.writeShellScriptBin "stop_parsec.sh" "pkill parsecd")
  ];

  # Give gurgi ssh access so it can run stop_parsec.sh
  # TODO: lock down permissions so that's the *only* thing it can do.
  users.users.gurgi = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPog+FoId+C37SnL1VfwRE11pGzzvxOM0GL0HjOL1Qqf gurgi@snowdon"
    ];
  };
}
