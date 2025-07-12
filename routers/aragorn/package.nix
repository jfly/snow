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
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBlRkJ2ZTdEZ3RTd25kSnRw
      S1lJN2FNSWdwM2thNTdVSU9rMW1DLzJFSUdrCk80cXhrdDl1SjFUK3JINEROcVlv
      bVNVSi8zdnJNajJFL3ZOOVVUbFM2ZUUKLS0tIHNaM2pHekVBWklsNEJKaGJIckV2
      MXdQbTRnVUVxWjU4ekVVNzR4d1NZbzQKQ2SEVYIgnipdBuuyKCmWwkw7kJCNY4fi
      wEkxE5eJ//SEICstP0jKL7cq2I8NrQyaMYxA2hGKLzYvjNtdyglipS/R5Q==
      -----END AGE ENCRYPTED FILE-----
    '';
  };
}
