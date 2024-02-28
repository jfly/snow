{
  inputs = {
    openwrt-imagebuilder.url = "github:astro/nix-openwrt-imagebuilder";
  };
  outputs = { self, nixpkgs, openwrt-imagebuilder }: {
    packages.x86_64-linux.my-router =
      let
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          overlays = import ../../overlays;
        };

        profiles = openwrt-imagebuilder.lib.profiles { inherit pkgs; };

        config = pkgs.stdenv.mkDerivation {
          name = "openwrt-config-files";
          src = ./files;
          installPhase = ''
            mkdir -p $out
            cp -r * $out/
          '';
        };

        rootPassword = pkgs.deage.string ''
          -----BEGIN AGE ENCRYPTED FILE-----
          YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBuQVdQcmRYQ3QzKzZ0NVpS
          MGdySEV2WmZQa0xsRDlROCtDaTAxTDU4M2d3Cmh2RVhYYnhsckE3cThHVDJmTlRW
          YmsrM1dxSFRFMi9UVy9oN3pmZGV2Q3cKLS0tIDNpaE1mektxTFdKcnIzUXdJR2sx
          RlRoa2hSUXdCbzNhNHBKZkYrMHJSSlEKeyH83LrYy7eVjQaN9Quh1xrbZ8mWPo/N
          DFA3oCgiHSO/k+lQoWMZoLsIcHWoxIRz52TfnQ==
          -----END AGE ENCRYPTED FILE-----
        '';

        routers-shared = pkgs.callPackage ../shared.nix { };
        identities = import ../../shared/identities.nix;
        homeAssistantPassword = routers-shared.users.homeAssistant.password;

        image-no-version = profiles.identifyProfile "tplink_archer-a6-v3" // {
          packages = [
            "luci"
            # Used by Home Assistant
            "luci-mod-rpc"
            # Used in uci-defaults script to add new users. Perhaps there's a
            # better way of doing this that doesn't bloat the image?
            "shadow-useradd"
          ];

          # Step 11 of https://openwrt.org/docs/guide-user/network/wifi/dumbap:
          # "To save resources on the wireless AP router, disable some now unneeded services"
          disabledServices = [
            "firewall"
            "dnsmasq"
            "odhcpd"
          ];

          files = pkgs.runCommand "image-files" { } ''
            mkdir -p $out/etc/uci-defaults
            cat > $out/etc/uci-defaults/99-custom <<EOF

            uci -q batch << EOI
            set system.@system[0].hostname='aragorn'
            commit
            EOI

            # Set root password.
            # https://forum.openwrt.org/t/set-password-in-new-custum-or-imagebuild-firmware/94219/2
            passwd root <<EOP
            ${rootPassword}
            ${rootPassword}
            EOP

            # Add a new user for Home Assistant to fetch presence information.
            useradd -r -s /bin/false home-assistant
            passwd home-assistant <<EOP
            ${homeAssistantPassword}
            ${homeAssistantPassword}
            EOP

            EOF

            cp -fr ${config}/etc/* $out/etc/

            substituteInPlace $out/etc/config/wireless \
              --replace "@wifi_password@" "${routers-shared.wifi.home.password}"

            substituteInPlace $out/etc/dropbear/authorized_keys \
              --replace "@authorized_key@" "${identities.jfly}"
          '';
        };
        built-no-version = openwrt-imagebuilder.lib.build image-no-version;
        last = l: builtins.elemAt l (builtins.length l - 1);
        nix-build-version = builtins.head (pkgs.lib.splitString "-" (last (pkgs.lib.splitString "/" built-no-version.outPath)));

        build-with-version = openwrt-imagebuilder.lib.build (image-no-version // {
          files = pkgs.runCommand "image-files" { } ''
            # Copy all the original files + make them writable.
            cp -r ${image-no-version.files} $out
            chmod -R +w $out

            # Store the version in an easily queried place.
            echo "${nix-build-version}" > $out/etc/nix-build-version

            # Now update the banner (actually, add a script to update the
            # banner) to print the nix build version as well.
            mkdir -p $out/etc/uci-defaults
            cat > $out/etc/uci-defaults/99-add-nix-version-to-banner <<EOF
            echo " Nix Version: ${nix-build-version}" >> /etc/banner
            echo " -----------------------------------------------------" >> /etc/banner
            EOF
          '';
        });

      in
      build-with-version // {
        hack-nix-version = nix-build-version;
      };
  };
}
