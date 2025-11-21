{ inputs, lib, ... }:
{
  # We need this here to work
  # around <https://git.clan.lol/clan/clan-core/issues/5850>.
  # I'm not sure why we still need a `nixpkgs.config` in the individual
  # machines as well, though... :shrug:.
  clan.pkgsForSystem =
    system:
    import inputs.nixpkgs {
      inherit system;

      config.allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "nvidia-x11"
          "nvidia-settings"
        ];
    };
}
