{ flake, pkgs }:

let
  inherit (flake.lib)
    snow-router
    deage
    ;
in
snow-router {
  inherit pkgs;
  hostname = "strider";
  profileName = "linksys_e8450-ubi";
  dumbap = false;
  config-files = ./files;
  config-template-values-by-file = {
    "/etc/config/ddns" = {
      "@cloudflare_api_token@" = deage.impureString ''
        -----BEGIN AGE ENCRYPTED FILE-----
        YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBrSENFbDRQOTRhMTUzWHRo
        NDBjbWxZN2RJNjRldEpoTE51ajJaWDdUN3g0Cml3ZXFCWFNlVncrMllyUVgzbWsz
        Ti8wUkV1WW5laVVlU1NHWDhqU21jT2MKLS0tIFJPaEQ4RTB5NDBsMGVmSXl3UURa
        d21aUW1rbTBOQkVxelo4OFhuWUZvekEKebLytJ0jsXhe8DN0q8xM30QQ/O3sokQa
        8RklmmCFI0aGaz0fNA8VqnmIDe7Pm/WyaHb0E6OOppA3V8E+Bxfzgh3h9SZZqm3u
        IzKa2gEU1QgvCBAKzA==
        -----END AGE ENCRYPTED FILE-----
      '';
    };
  };

  rootPassword = deage.impureString ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBEcGE3M0VUZHBXRVRNSG5P
    TGg2WmFtVmJCeGpyd2wyVmozMS9Jeit2UkEwCm9HbWZVL3FnVWtnazJpNlEybFBw
    TFppZXBzU3FjMlZmVTNRa1diMmpwRHcKLS0tIFVhcSt4aDlqOG8zOWdtYW9wME9P
    TzFyZzcxV3o1YjI4bW1PU3dqZ2lKRnMK5c9Oh+d54VZRI9OdsIltejaHyQD+8QO0
    Psb9arR4U0ZvIPLccGd9TGPNF+q72tnD77kaCg==
    -----END AGE ENCRYPTED FILE-----
  '';
  mqtt = {
    username = "strider";
    password = deage.impureString ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBLRlRJWUdjRjdXc0JpL2Fh
      QmkwZ1JHRVVPZXRjRTNpVEI4VW9senBrV1hnCkFPWWNuSFlYMS82d0s0Q0wwdWY5
      U0FXKzJPTkh1Tk91Y2d5R3JjQThXa0UKLS0tIHFGamtOLzd0WGV6RDhnOUtteStJ
      ZkRGUlJtRms1T1VoV2hxOUhWYnVsNGsK6xpJECTrq5S1HRmNbrI8fSDZfKRiMlzs
      MM1VUK4Mj+UjXPfzF39zyDAD2ULbr4lXHBwLSwPCio9zc8FwneQ=
      -----END AGE ENCRYPTED FILE-----
    '';
  };
}
