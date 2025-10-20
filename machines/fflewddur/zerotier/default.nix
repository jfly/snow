{
  imports = [
    ./static-peers.nix
    ./dns.nix
  ];

  # TODO: back up controller data

  # TODO: contribute docs to clan-core explaining how to do all this:
  #       https://git.clan.lol/clan/clan-core/issues/1268

  # TODO: set up an exit node: https://docs.zerotier.com/exitnode/
}
