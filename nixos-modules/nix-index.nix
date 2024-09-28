{ inputs, ... }:

{
  imports = [ inputs.nix-index-database.nixosModules.nix-index ];
  programs.nix-index-database.comma.enable = true;

  # Enabling nix-index-database (above) enables nix-index, which enables all
  # these shell integrations for command-not-found. I don't like that
  # functionality, so turn it off!
  programs.nix-index.enableBashIntegration = false;
  programs.nix-index.enableZshIntegration = false;
  programs.nix-index.enableFishIntegration = false;
}
