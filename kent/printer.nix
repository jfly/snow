{ pkgs, ... }:
{
  # Set up printer
  services.printing = {
    enable = true;
    defaultShared = true;
    browsing = true;

    # TODO: enable printer
    # # brlaser doesn't explicitly mention the Brother HL-2240, but according to
    # # https://github.com/pdewacht/brlaser/issues/136, *any* entry marked
    # # 'brlaser' works? :shrug:
    # drivers = [ pkgs.brlaser ];
  };

  # TODO: enable printer
  # hardware.printers.ensurePrinters = [
  #   {
  #     name = "brother";
  #     location = "man cave";
  #     description = "brother hl-2240";
  #     deviceUri = "usb://Brother/HL-2240%20series?serial=J1N651698";
  #     # brlaser doesn't explicitly mention the Brother HL-2240, but according to
  #     # https://github.com/pdewacht/brlaser/issues/136, *any* entry marked
  #     # 'brlaser' works? :shrug:
  #     model = "drv:///brlaser.drv/br2220.ppd";
  #   }
  # ];

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  # Set up samba (from https://nixos.wiki/wiki/Samba#Printer_sharing)
  services.samba = {
    enable = true;
    package = pkgs.sambaFull;
    openFirewall = true;
    extraConfig = ''
      load printers = yes
      printing = cups
      printcap name = cups
    '';
    shares = {
      printers = {
        comment = "All Printers";
        path = "/var/spool/samba";
        public = "yes";
        browseable = "yes";
        # to allow user 'guest account' to print.
        "guest ok" = "yes";
        writable = "no";
        printable = "yes";
        "create mode" = 0700;
      };
    };
  };
  systemd.tmpfiles.rules = [
    "d /var/spool/samba 1777 root root -"
  ];
}
