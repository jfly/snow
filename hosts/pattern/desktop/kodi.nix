{ flake, ... }:

{
  imports = [
    flake.nixosModules.kodi-colusita
  ];

  services.kodi-colusita = {
    enable = true;
    moonlight.enable = true;
  };
}
