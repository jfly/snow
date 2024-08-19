{
  inputs = {
    # TODO: switch back to upstream once the hashes are fixed
    # openwrt-imagebuilder.url = "github:jfly/nix-openwrt-imagebuilder/update-hashes";
    openwrt-imagebuilder.url = "github:astro/nix-openwrt-imagebuilder";
  };
  outputs = { self, nixpkgs, openwrt-imagebuilder }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = import ../overlays { };
      };
      snow-router = pkgs.callPackage ./snow-router.nix {
        inherit openwrt-imagebuilder;
      };
    in
    {
      packages.${system} = {
        deploy = pkgs.writeShellApplication {
          name = "deploy";
          runtimeInputs = [ ];
          text = builtins.readFile ./scripts/deploy.sh;
        };
        pull = pkgs.writeShellApplication {
          name = "pull";
          runtimeInputs = [ ];
          text = builtins.readFile ./scripts/pull.sh;
        };

        strider = snow-router {
          hostname = "strider";
          profileName = "linksys_e8450-ubi";
          dumbap = false;
          config-files = ./strider/files;
          config-template-values-by-file = {
            "/etc/config/ddns" = {
              "@cloudflare_api_token@" = pkgs.deage.string ''
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

          rootPassword = pkgs.deage.string ''
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
            password = pkgs.deage.string ''
              -----BEGIN AGE ENCRYPTED FILE-----
              YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBiVHc1UXJmMkJpeVdlTWFX
              TzB3TnFHZHBwaG1hbGhqb2k1VUpWYyt4bFQwCnJodmsvQ3VsOWFtWUZsbnBJM2pO
              SzBRTDM3VVpnSnF4dE5KZ29uVm9wd3MKLS0tIHRxQlhTOSt4citFbm9RalFFdndz
              OHZDdVhFdnU3eUZESjNabVcraDhlbEEKAW54k9Ne4JZ76adEBmvrcKrxdVcMQe+q
              pbReTtYwFdORWth/mhrKJG1xffW2jNzORDbfow==
              -----END AGE ENCRYPTED FILE-----
            '';
          };
        };
        aragorn = snow-router {
          hostname = "aragorn";
          profileName = "tplink_archer-a6-v3";
          dumbap = true;
          config-files = ./aragorn/files;
          rootPassword = pkgs.deage.string ''
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
            password = pkgs.deage.string ''
              -----BEGIN AGE ENCRYPTED FILE-----
              YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBmeFBZeUo1cVFJeVUvK1hL
              cGkvT0psbUxnUDlDelFTSmhpOXY4TUtxKzFjCmZycm5BWS9ZYXA2aUFwYyt1bi96
              cTNDRFFDaEsrK2FPQ1RvOWpvVVhSbUUKLS0tIHFrWGpDN1BTZFNmaVJiOUVKZU1i
              TC9ULzdsbCsyL3hDbGVqdjAwUGlQNUkKGzVGPVjUblP8AeZI1uPhMHwZMk5yNxnI
              W3vQFZe+gBiYFpe6bKA+v8kJh7+t/xeraKvBRQ==
              -----END AGE ENCRYPTED FILE-----
            '';
          };
        };
        elfstone = snow-router {
          hostname = "elfstone";
          profileName = "tplink_archer-a6-v3";
          dumbap = true;
          config-files = ./elfstone/files;
          rootPassword = pkgs.deage.string ''
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
            password = pkgs.deage.string ''
              -----BEGIN AGE ENCRYPTED FILE-----
              YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBuR1ByeEQ1MkNpL3UxTlUy
              Wlc1L0tUUmZ2N2RDeFJQWjZ0dERyV1E1djI4CjBWSUNodjl3OWZqaGhSZWxSN3ZN
              VjJhNHlVOHJkTUdLMVFQTFpyU1hiejAKLS0tIElsbytMdEpVQmlTUDQzYytOanJz
              OFE2dER3VTFVeVhtTzFMWFlhSFZWajQK5bmkkgas1uyi8xkMKNUH4i7F9mHzWZ9S
              eKaXqKII7KroBW0sRs36rjm5LibqY7fvBqUE7w==
              -----END AGE ENCRYPTED FILE-----
            '';
          };
        };
      };
    };
}
