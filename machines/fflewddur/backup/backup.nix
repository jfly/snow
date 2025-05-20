{ flake, ... }:

{
  imports = [ flake.nixosModules.backup ];

  snow.backup = {
    enable = true;

    paths = [ "/mnt/bay/archive" ];
  };
}
