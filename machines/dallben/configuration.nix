{ flake, lib, ... }:

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

  # Workaround for <https://github.com/NixOS/nixpkgs/issues/493934>, copied
  # from
  # <https://github.com/pinpox/opencrow/commit/3623a1a30c0ba8aabd0de43255d08bc318100fb0>.
  security.pam.services.login.updateWtmp = lib.mkForce false;

  services.kodi-colusita = {
    enable = true;
    startOnBoot = true;
    moonlight.enable = true;
  };

  # This device regularly goes to sleep.
  snow.monitoring.alertIfDown = false;

  disko.devices.disk.main.device = "/dev/disk/by-id/nvme-CT250P2SSD8_2117E59A4AF5";

  # Prevent the screen from going dark. It's a source of endless confusion when
  # we turn on the TV to find that the screen is still dark (until we do
  # something to "wake up" X11).
  services.xserver.serverFlagsSection = ''
    Option "BlankTime" "0"
    Option "DPMS" "false"
  '';
}
