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
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBuR1ByeEQ1MkNpL3UxTlUy
      Wlc1L0tUUmZ2N2RDeFJQWjZ0dERyV1E1djI4CjBWSUNodjl3OWZqaGhSZWxSN3ZN
      VjJhNHlVOHJkTUdLMVFQTFpyU1hiejAKLS0tIElsbytMdEpVQmlTUDQzYytOanJz
      OFE2dER3VTFVeVhtTzFMWFlhSFZWajQK5bmkkgas1uyi8xkMKNUH4i7F9mHzWZ9S
      eKaXqKII7KroBW0sRs36rjm5LibqY7fvBqUE7w==
      -----END AGE ENCRYPTED FILE-----
    '';
  };
}
