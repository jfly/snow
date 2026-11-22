{ config, pkgs, ... }:
{
  # From https://wiki.nixos.org/wiki/Printing#Enable_auto-discovery_of_network_printers
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  services.printing = {
    enable = true;
    # logLevel = "debug";
    drivers = [
      pkgs.cups-filters
      pkgs.cups-browsed
    ];
  };

  # https://wiki.nixos.org/wiki/Printing#Enable_auto-discovery_of_USB_printers
  services.ipp-usb.enable = true;

  # https://wiki.nixos.org/wiki/Scanners
  # Ok, not technically printers, but they're in a similar family :p
  hardware.sane.enable = true;
  users.users.${config.snow.user.name}.extraGroups = [
    "scanner"
    "lp"
  ];
}
