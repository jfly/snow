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
        YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSArQjNRYWxLdyszY0dBRmNL
        RmJiY3R1NTk1TVcvWDlvVVAwM1luNzZvN2cwCnFrNjRwMDBONFlGTmZ4aXBLV0Rj
        UElRc2tOL0Zlc1VRRVpmOXZwMU1HSzgKLS0tIHNVMVhKU3EzN0x5NlVkN0J2b1NL
        M2tkb3BiVUJ0SmRwZ3JtS1c0WmNDeVkKd6aIxcBae2D9laj8XgGYow6dUmb2GJQk
        iIrz94V8b59mPw9d8plEQdCBN4L3auY9H2EJQ8ltPMiF4o5Pl2cWT/G5RlRjda+d
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
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBiVHc1UXJmMkJpeVdlTWFX
      TzB3TnFHZHBwaG1hbGhqb2k1VUpWYyt4bFQwCnJodmsvQ3VsOWFtWUZsbnBJM2pO
      SzBRTDM3VVpnSnF4dE5KZ29uVm9wd3MKLS0tIHRxQlhTOSt4citFbm9RalFFdndz
      OHZDdVhFdnU3eUZESjNabVcraDhlbEEKAW54k9Ne4JZ76adEBmvrcKrxdVcMQe+q
      pbReTtYwFdORWth/mhrKJG1xffW2jNzORDbfow==
      -----END AGE ENCRYPTED FILE-----
    '';
  };
}
