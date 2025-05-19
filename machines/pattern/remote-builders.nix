{
  nix.distributedBuilds = true;
  nix.settings.builders-use-substitutes = true;

  programs.ssh = {
    # `nix-daemon` connects as root, so we need a known hosts entry.
    knownHosts = {
      "build-box.nix-community.org" = {
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIElIQ54qAy7Dh63rBudYKdbzJHrrbrrMXLYl7Pkmk88H";
      };
    };
    # We need some way to use my personal ssh key to connect, but `nix-daemon`
    # running as root can't use my passphrase protected ssh key. Hack from
    # https://fzakaria.com/2024/07/10/nix-remote-building-with-yubikey
    # The proper fix would be for nix to support ssh agent forwarding (similar
    # to ssh): https://github.com/NixOS/nix/issues/10124
    extraConfig = ''
      Host build-box.nix-community.org
        IdentityAgent /run/user/1000/ssh-agent
    '';
  };
}
