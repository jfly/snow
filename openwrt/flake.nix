# TODO: explore https://www.liminix.org/ as an alternative to all this
{
  inputs = {
    # Implements a very hacky workaround for
    # https://github.com/astro/nix-openwrt-imagebuilder/issues/38
    openwrt-imagebuilder.url = "github:jfly/nix-openwrt-imagebuilder/custom-packages";
    # openwrt-imagebuilder.url = "github:astro/nix-openwrt-imagebuilder";
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
          rootPassword = pkgs.deage.string ''
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBEcGE3M0VUZHBXRVRNSG5P
            TGg2WmFtVmJCeGpyd2wyVmozMS9Jeit2UkEwCm9HbWZVL3FnVWtnazJpNlEybFBw
            TFppZXBzU3FjMlZmVTNRa1diMmpwRHcKLS0tIFVhcSt4aDlqOG8zOWdtYW9wME9P
            TzFyZzcxV3o1YjI4bW1PU3dqZ2lKRnMK5c9Oh+d54VZRI9OdsIltejaHyQD+8QO0
            Psb9arR4U0ZvIPLccGd9TGPNF+q72tnD77kaCg==
            -----END AGE ENCRYPTED FILE-----
          '';
          mqttPassword = pkgs.deage.string ''
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBiVHc1UXJmMkJpeVdlTWFX
            TzB3TnFHZHBwaG1hbGhqb2k1VUpWYyt4bFQwCnJodmsvQ3VsOWFtWUZsbnBJM2pO
            SzBRTDM3VVpnSnF4dE5KZ29uVm9wd3MKLS0tIHRxQlhTOSt4citFbm9RalFFdndz
            OHZDdVhFdnU3eUZESjNabVcraDhlbEEKAW54k9Ne4JZ76adEBmvrcKrxdVcMQe+q
            pbReTtYwFdORWth/mhrKJG1xffW2jNzORDbfow==
            -----END AGE ENCRYPTED FILE-----
          '';
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
          mqttPassword = pkgs.deage.string ''
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
    };
}
