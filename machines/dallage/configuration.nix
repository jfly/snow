{ flake, ... }:
{
  networking.hostName = "dallage";
  time.timeZone = "America/Chicago";

  imports = [
    flake.nixosModules.shared
    ./hardware-configuration.nix
    ./disko.nix
    ./gpu.nix
    ./bluetooth.nix
    flake.nixosModules.xmonad-basic
    flake.nixosModules.kodi-colusita
  ];

  services.kodi-colusita = {
    enable = true;
    startOnBoot = true;
    cecdaemon.enable = false;
    moonlight = {
      enable = true;
      startOnKeycode = "KEY_RED";
    };
  };

  # This device regularly goes to sleep.
  snow.monitoring.alertIfDown = false;

  # Not worth backing up: this machine is stateless and easier to recreate from
  # scratch.
  snow.backup.enable = false;

  disko.devices.disk.main.device = "/dev/disk/by-id/nvme-eui.0025388101c88cbd";

  # Prevent the screen from going dark. It's a source of endless confusion when
  # we turn on the TV to find that the screen is still dark (until we do
  # something to "wake up" X11).
  services.xserver.serverFlagsSection = ''
    Option "BlankTime" "0"
    Option "DPMS" "false"
  '';
}
