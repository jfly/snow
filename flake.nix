{
  description = "snow";

  inputs = {
    # Choose not to download darwin dependencies (saves some resources on Linux, see
    # https://github.com/ryantm/agenix#install-module-via-flakes).
    agenix.inputs.darwin.follows = "";
    agenix.inputs.home-manager.follows = "home-manager";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    on-air.inputs.nixpkgs.follows = "nixpkgs";
    on-air.url = "github:jfly/on-air";
    openwrt-imagebuilder.url = "github:astro/nix-openwrt-imagebuilder";
    # openwrt-imagebuilder.url = "github:jfly/nix-openwrt-imagebuilder/update-hashes";
    poetry2nix.url = "github:nix-community/poetry2nix";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    pr-tracker.inputs.nixpkgs.follows = "nixpkgs";
    pr-tracker.url = "github:molybdenumsoftware/pr-tracker";
    shtuff.inputs.nixpkgs.follows = "nixpkgs";
    shtuff.url = "github:jfly/shtuff";
    # TODO: switch back to upstream when/if
    # https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/merge_requests/344/
    # is merged.
    # simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
    simple-nixos-mailserver.url = "gitlab:jflysohigh/nixos-mailserver/dkim-path";
    systems.url = "github:nix-systems/x86_64-linux";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    with-alacritty.inputs.nixpkgs.follows = "nixpkgs";
    with-alacritty.url = "github:FatBoyXPC/with-alacritty";
  };

  outputs =
    raw-inputs:
    let
      flake = raw-inputs.self;
      inputs = raw-inputs // {
        inherit (flake.lib) agenix-rooter;
      };
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [ ./flake-modules ];
    };
}
