{ config, lib, pkgs, ... }:

{
  imports = [
    (import ../sources.nix).home-manager-nixos # Set up home-manager.
  ];

  options = {
    snow = {
      user = {
        file = lib.mkOption {
          type = lib.types.attrs;
          description = lib.mdDoc ">>> <<<";
        };
      };
    };
  };

  config = {
    home-manager.useGlobalPkgs = true;
    home-manager.users.${config.snow.user.name} = hm@{ ... }:
      let
        link = hm.config.lib.file.mkOutOfStoreSymlink;
        maybeTransformFile = file:
          if builtins.hasAttr "target" file then
            {
              source =
                if builtins.pathExists file.target then
                  link file.target
                else
                  builtins.throw "Could not find ${file.target}";
            }
          else
            file
        ;
      in
      {
        home.stateVersion = "22.05";
        home.username = config.snow.user.name;
        home.homeDirectory = "/home/${config.snow.user.name}";

        home.file = lib.mapAttrs'
          (name: file:
            lib.nameValuePair name (maybeTransformFile file)
          )
          config.snow.user.file;
      };

    snow.user.file.sd.target = ../dotfiles/homies/sd;
    environment.systemPackages = with pkgs; [
      (pkgs.callPackage ../shared/sd { })
    ];
    snow.user.file.bin.target = ../dotfiles/homies/bin;
  };
}
