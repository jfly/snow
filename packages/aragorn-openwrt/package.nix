{ flake, pkgs }:

let
  inherit (flake.lib)
    snow-router
    deage
    ;
in
snow-router {
  inherit pkgs;
  hostname = "aragorn";
  profileName = "tplink_archer-a6-v3";
  dumbap = true;
  config-files = ./files;
  rootPassword = deage.impureString ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBuQVdQcmRYQ3QzKzZ0NVpS
    MGdySEV2WmZQa0xsRDlROCtDaTAxTDU4M2d3Cmh2RVhYYnhsckE3cThHVDJmTlRW
    YmsrM1dxSFRFMi9UVy9oN3pmZGV2Q3cKLS0tIDNpaE1mektxTFdKcnIzUXdJR2sx
    RlRoa2hSUXdCbzNhNHBKZkYrMHJSSlEKeyH83LrYy7eVjQaN9Quh1xrbZ8mWPo/N
    DFA3oCgiHSO/k+lQoWMZoLsIcHWoxIRz52TfnQ==
    -----END AGE ENCRYPTED FILE-----
  '';
  mqtt = {
    username = "aragorn";
    password = deage.impureString ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBmeFBZeUo1cVFJeVUvK1hL
      cGkvT0psbUxnUDlDelFTSmhpOXY4TUtxKzFjCmZycm5BWS9ZYXA2aUFwYyt1bi96
      cTNDRFFDaEsrK2FPQ1RvOWpvVVhSbUUKLS0tIHFrWGpDN1BTZFNmaVJiOUVKZU1i
      TC9ULzdsbCsyL3hDbGVqdjAwUGlQNUkKGzVGPVjUblP8AeZI1uPhMHwZMk5yNxnI
      W3vQFZe+gBiYFpe6bKA+v8kJh7+t/xeraKvBRQ==
      -----END AGE ENCRYPTED FILE-----
    '';
  };
}
