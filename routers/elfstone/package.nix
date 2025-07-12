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
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSAzbkxQd3N4aGp2dXIyQ1Y0
      d2RMdkkyaTFRM2R4dE9OMUFBRDRRWFJHWUQwCldmOVNUcUtCT1l2WCtsTWZ1VkVo
      S0tueVRqaXQrQWFWSDFRMkNiMHQzejgKLS0tIGdZY0d2R004YzcrRTZ3WUcramVL
      Y1lWa0ZGM0w3S0pXV1J4aUpjZ0RMRmcKtaNdTvvw3AV+nRyZa1AGNuWNfk5CloDs
      MsrTPSyYLfK1V290tDu892KTc42cA9HaP6WriSK9V4of8ZpukQ9+8w==
      -----END AGE ENCRYPTED FILE-----
    '';
  };
}
