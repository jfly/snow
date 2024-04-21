{
  inputs = {
    # Implements a very hacky workaround for
    # https://github.com/astro/nix-openwrt-imagebuilder/issues/38
    openwrt-imagebuilder.url = "github:jfly/nix-openwrt-imagebuilder/custom-packages";
    # openwrt-imagebuilder.url = "github:astro/nix-openwrt-imagebuilder";
  };
  outputs = { self, nixpkgs, openwrt-imagebuilder }: {
    packages.x86_64-linux.my-router =
      let
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          overlays = import ../../overlays;
        };

        profiles = openwrt-imagebuilder.lib.profiles {
          inherit pkgs;
          release = "23.05.2";
        };

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

        mqttPassword = pkgs.deage.string ''
          -----BEGIN AGE ENCRYPTED FILE-----
          YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBmeFBZeUo1cVFJeVUvK1hL
          cGkvT0psbUxnUDlDelFTSmhpOXY4TUtxKzFjCmZycm5BWS9ZYXA2aUFwYyt1bi96
          cTNDRFFDaEsrK2FPQ1RvOWpvVVhSbUUKLS0tIHFrWGpDN1BTZFNmaVJiOUVKZU1i
          TC9ULzdsbCsyL3hDbGVqdjAwUGlQNUkKGzVGPVjUblP8AeZI1uPhMHwZMk5yNxnI
          W3vQFZe+gBiYFpe6bKA+v8kJh7+t/xeraKvBRQ==
          -----END AGE ENCRYPTED FILE-----
        '';

        routers-shared = pkgs.callPackage ../shared.nix { };
        identities = import ../../shared/identities.nix;

        # Urg, right now installing custom packages is a *pain*. See
        # https://github.com/astro/nix-openwrt-imagebuilder/issues/38 for a
        # feature request to make this easier to deal with.
        wifi-presence = {
          file = pkgs.fetchurl {
            url = "https://github.com/awilliams/wifi-presence/releases/download/v0.3.0/wifi-presence_0.3.0-1_mipsel_24kc.ipk";
            sha256 = "sha256-kCPU9q8mc+qKt6/BMgBfGoO3ZqvhZRFsmBkuZTTRou4=";
          };
          filename = "wifi-presence_0.3.0-1_mipsel_24kc.ipk";
        };
        built-no-version = (openwrt-imagebuilder.lib.build (profiles.identifyProfile "tplink_archer-a6-v3" // {
          packages = [
            "luci"
            # Remove the stripped down version of hostapd in favor of the full
            # version. This is necessary for awilliams/wifi-presence. See
            # https://github.com/awilliams/wifi-presence?tab=readme-ov-file#hostapd
            # for details.
            "-wpad-basic-mbedtls"
            "wpad-mbedtls"
          ];
          hackExtraPackages = [ "wifi-presence" ];

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

            EOF

            cp -fr ${config}/etc/* $out/etc/

            substituteInPlace $out/etc/config/wireless \
              --replace-fail "@wifi_password@" "${routers-shared.wifi.home.password}" \
              --replace-fail "@wifi_iot_password@" "${routers-shared.wifi.iot.password}"

            substituteInPlace $out/etc/config/wifi-presence \
              --replace-fail "@mqtt_password@" "${mqttPassword}"

            substituteInPlace $out/etc/dropbear/authorized_keys \
              --replace-fail "@authorized_key@" "${identities.jfly}"
          '';
        })).overrideAttrs
          (finalAttrs: prevAttrs: {
            configurePhase = ''
              ${prevAttrs.configurePhase}

              ln -s ${wifi-presence.file} packages/${wifi-presence.filename}
            '';
          });
        last = l: builtins.elemAt l (builtins.length l - 1);
        nix-build-version = builtins.head (pkgs.lib.splitString "-" (last (pkgs.lib.splitString "/" built-no-version.outPath)));

        built-with-version = built-no-version.overrideAttrs
          (finalAttrs: prevAttrs: {
            configurePhase = ''
              ${prevAttrs.configurePhase}

              # Store the version in an easily queried place.
              echo "${nix-build-version}" > ./files/etc/nix-build-version

              # Now update the banner (actually, add a script to update the
              # banner) to print the nix build version as well.
              mkdir -p ./files/etc/uci-defaults
              cat > ./files/etc/uci-defaults/99-add-nix-version-to-banner <<EOF
              echo " Nix Version: ${nix-build-version}" >> /etc/banner
              echo " -----------------------------------------------------" >> /etc/banner
              EOF
            '';
            hack-nix-version = nix-build-version;
          });
      in
      built-with-version;
  };
}
