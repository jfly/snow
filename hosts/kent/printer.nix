{ pkgs, ... }:
{
  # Set up printer
  services.printing = {
    stateless = true;
    enable = true;
    defaultShared = true;
    browsing = true;
    openFirewall = true;

    listenAddresses = [ "*:631" ];
    allowFrom = [ "all" ];

    # brlaser doesn't explicitly mention the Brother HL-2240, but according to
    # https://github.com/pdewacht/brlaser/issues/136, *any* entry marked
    # 'brlaser' works? :shrug:
    drivers = [
      # Hack to default to Letter rather than A4. This might be the same issue
      # reported here: https://github.com/NixOS/nixpkgs/issues/53027.
      (pkgs.symlinkJoin {
        name = "brlaser-letter-hack";
        paths = [ pkgs.brlaser ];
        postBuild = ''
          cp --remove-destination $(readlink $out/share/cups/drv/brlaser.drv) $out/share/cups/drv/brlaser.drv
          substituteInPlace $out/share/cups/drv/brlaser.drv \
            --replace-fail "*MediaSize A4" "MediaSize A4" \
            --replace-fail "MediaSize Letter" "*MediaSize Letter"
        '';
      })
    ];
  };

  hardware.printers.ensurePrinters = [
    {
      name = "brother";
      location = "man cave";
      description = "brother hl-2240";
      deviceUri = "usb://Brother/HL-2240%20series?serial=J1N651698";
      # brlaser doesn't explicitly mention the Brother HL-2240, but according to
      # https://github.com/pdewacht/brlaser/issues/136, *any* entry marked
      # 'brlaser' works? :shrug:
      model = "drv:///brlaser.drv/br2220.ppd";
    }
  ];

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
    package = pkgs.sambaFull.override {
      # Workaround for <https://github.com/NixOS/nixpkgs/issues/369777#issuecomment-2606843434>
      enableCephFS = false;
    };
    openFirewall = true;
    settings = {
      global = {
        "load printers" = "yes";
        "printing" = "cups";
        "printcap name" = "cups";
      };
      printers = {
        comment = "All Printers";
        path = "/var/spool/samba";
        public = "yes";
        browseable = "yes";
        # to allow user 'guest account' to print.
        "guest ok" = "yes";
        writable = "no";
        printable = "yes";
        "create mode" = 700;
      };
    };
  };
  systemd.tmpfiles.rules = [
    "d /var/spool/samba 1777 root root -"
  ];
}
