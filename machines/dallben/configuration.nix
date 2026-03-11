{ flake, ... }:

{
  networking.hostName = "dallben";
  time.timeZone = "America/Los_Angeles";
  services.openssh.enable = true;

  imports = [
    flake.nixosModules.shared
    ./hardware-configuration.nix
    ./disko.nix
    ./gpu.nix
    ./bluetooth.nix
    flake.nixosModules.xmonad-basic
    flake.nixosModules.kodi-colusita
    ./arr
  ];

  services.kodi-colusita = {
    enable = true;
    startOnBoot = true;
    moonlight.enable = true;
  };

  # This device regularly goes to sleep.
  snow.monitoring.alertIfDown = false;

  # Prevent the screen from going dark. It's a source of endless confusion when
  # we turn on the TV to find that the screen is still dark (until we do
  # something to "wake up" X11).
  services.xserver.serverFlagsSection = ''
    Option "BlankTime" "0"
    Option "DPMS" "false"
  '';
}
