{
  flake,
  modulesPath,
  ...
}:

let
  identities = flake.lib.identities;
in
{
  # https://wiki.nixos.org/wiki/Creating_a_NixOS_live_CD
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

  # The default compression algorithm produces the smallest images, but takes a *while*.
  isoImage.squashfsCompression = "gzip -Xcompression-level 1";

  # Allow ssh as the root user. nixos-anywhere needs this:
  # <https://github.com/nix-community/nixos-anywhere/pull/293#pullrequestreview-1962541552>
  users.users.root.openssh.authorizedKeys.keys = [ identities.jfly ];
}
