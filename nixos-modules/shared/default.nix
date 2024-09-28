{
  flake,
  flake',
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.agenix-rooter.nixosModules.default
    flake.nixosModules.nix-index
  ];

  # Ensure that commands like `nix repl` and `nix-shell` have access to the
  # same nixpkgs we use to install everything else.
  nix.nixPath = [ "nixpkgs=${pkgs.path}" ];

  # Use latest nix. There are apparently issues with it [0] [1], but I want
  # to see if they affect me personally.
  # Furthermore, the newer version contains one fix [2] I do care about.
  # [0]: https://github.com/NixOS/nixpkgs/pull/315858
  # [1]: https://github.com/NixOS/nixpkgs/pull/315262
  # [2]: https://github.com/NixOS/nix/pull/9930
  nix.package = pkgs.nixVersions.latest;

  environment.systemPackages = with pkgs; [
    flake'.packages.neovim
    wget
    curl
    tmux
  ];

  programs.mosh.enable = true;

  environment.variables = {
    EDITOR = "vim";
  };

  users.groups.media = {
    gid = 1002;
  };

  age.rooter.generatedForHostDir = ../../secrets;
}
