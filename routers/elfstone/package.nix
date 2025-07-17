{ flake, pkgs }:

let
  inherit (flake.lib)
    snow-router
    deage
    ;
in
snow-router {
  inherit pkgs;
  hostname = "elfstone";
  profileName = "tplink_archer-a6-v3";
  dumbap = true;
  config-files = ./files;
  rootPassword = deage.impureString ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBLVjRrb1daanRtNUZzbFYx
    YUt0TlNwKzg0bHhVSjJER25OSFNQMVMyNkRzCjJNLzN0REpvMVFXUXRoenM1VWNr
    clJycS9ORG8ycEpJVHp3T1pxNkJtSHMKLS0tIEVPM0ZRa2J1YkpiTnR4K2o1L2My
    TW9BYk0zbXJlVGhVQXhDTW1kd1hnYW8Kls5ZoKVb4PW/80Sme03ARO3y7kIT7oUb
    lo01mCVOAufSp874zcdprr+0OGstXlaZZtISlw==
    -----END AGE ENCRYPTED FILE-----
  '';
  mqtt = {
    username = "elfstone";
    password = deage.impureString ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBOMmFnNWQ4SU9ob1k5dHBK
      NG9UMlBaa0lEaVVHekcxNEVNd3dLeDh5R3dnCkFJNHJjeS80b3oxWUxGaXNrZVRD
      TmlFK3FxU3FBL3lxVzNGYk1wQmxLUE0KLS0tIDN5em9oQXpHMXZPazFZU2dXaS9q
      WXo4bVBka2hsTEZtdXF3aFBER3lSdjQKpxydM40/IoWK5WxYS9TTa1sb9ZO6Ux8G
      J6M6KyCZuNBnULZH4RDkD6EzLQevZxqXCBuzbJ7qm21iBlAPZD+3JQ==
      -----END AGE ENCRYPTED FILE-----
    '';
  };
}
