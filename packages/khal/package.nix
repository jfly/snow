{ flake', pkgs, ... }:
let
  khalConfig = pkgs.writeTextFile {
    name = "khal.conf";
    text = # toml
      ''
        [calendars]

        [[calendars]]
        path = ~/pim/calendars/**
        type = discover

        [locale]
        timeformat = %H:%M
        dateformat = %Y-%m-%d
        longdateformat = %Y-%m-%d
        datetimeformat = %Y-%m-%d %H:%M
        longdatetimeformat = %Y-%m-%d %H:%M

        [default]
        default_calendar = jeremyfleischman@gmail.com
      '';
  };
in
flake'.packages.lib.wrapPackage pkgs.khal ''
  wrapProgram $out/bin/khal --add-flags "--config ${khalConfig}"
  wrapProgram $out/bin/ikhal --add-flags "--config ${khalConfig}"
''
