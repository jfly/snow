{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  description = ''
    An agenix extension that lets you manage secrets encrypted
    with a single master key and easily re-encrypt them for each host. Like
    agenix-rekey, but you actually commit the "rekeyed" files instead of doing an
    impure build to produce a local derivation that contains them.
  '';
  outputs = { self, nixpkgs, ... }: import ./default.nix { inherit nixpkgs; };
}
