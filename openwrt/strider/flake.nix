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
          YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBEcGE3M0VUZHBXRVRNSG5P
          TGg2WmFtVmJCeGpyd2wyVmozMS9Jeit2UkEwCm9HbWZVL3FnVWtnazJpNlEybFBw
          TFppZXBzU3FjMlZmVTNRa1diMmpwRHcKLS0tIFVhcSt4aDlqOG8zOWdtYW9wME9P
          TzFyZzcxV3o1YjI4bW1PU3dqZ2lKRnMK5c9Oh+d54VZRI9OdsIltejaHyQD+8QO0
          Psb9arR4U0ZvIPLccGd9TGPNF+q72tnD77kaCg==
          -----END AGE ENCRYPTED FILE-----
        '';
        cloudflareApiToken = pkgs.deage.string ''
          -----BEGIN AGE ENCRYPTED FILE-----
          YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSArQjNRYWxLdyszY0dBRmNL
          RmJiY3R1NTk1TVcvWDlvVVAwM1luNzZvN2cwCnFrNjRwMDBONFlGTmZ4aXBLV0Rj
          UElRc2tOL0Zlc1VRRVpmOXZwMU1HSzgKLS0tIHNVMVhKU3EzN0x5NlVkN0J2b1NL
          M2tkb3BiVUJ0SmRwZ3JtS1c0WmNDeVkKd6aIxcBae2D9laj8XgGYow6dUmb2GJQk
          iIrz94V8b59mPw9d8plEQdCBN4L3auY9H2EJQ8ltPMiF4o5Pl2cWT/G5RlRjda+d
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

        routers-shared = pkgs.callPackage ../shared.nix { };
        identities = import ../../shared/identities.nix;

        # Urg, right now installing custom packages is a *pain*. See
        # https://github.com/astro/nix-openwrt-imagebuilder/issues/38 for a
        # feature request to make this easier to deal with.
        wifi-presence = {
          file = pkgs.fetchurl {
            url = "https://github.com/awilliams/wifi-presence/releases/download/v0.3.0/wifi-presence_0.3.0-1_aarch64_cortex-a53.ipk";
            sha256 = "sha256-yN2wDs723HGfmEKS4x1QQwCv4938edRQTJaVGwdQe7Y=";
          };
          filename = "wifi-presence_0.3.0-1_aarch64_cortex-a53.ipk";
        };
        built-no-version = (openwrt-imagebuilder.lib.build (profiles.identifyProfile "linksys_e8450-ubi" // {
          packages = [
            "luci"
            # Useful debugging utils.
            "lsblk"
            "gdisk"
            "usbutils"
            # From step 3 of https://openwrt.org/docs/guide-user/storage/usb-drives-quickstart#procedure
            "block-mount"
            "e2fsprogs"
            "kmod-fs-ext4"
            "kmod-usb-storage"
            "kmod-usb2"
            "kmod-usb3"
            # From https://openwrt.org/docs/guide-user/services/ddns/client#requirements
            "ddns-scripts"
            "luci-app-ddns"
            "ddns-scripts-cloudflare"
            "curl"
            "ca-bundle"
            # More utils
            "coreutils-nohup"
            # Remove the stripped down version of hostapd in favor of the full
            # version. This is necessary for awilliams/wifi-presence. See
            # https://github.com/awilliams/wifi-presence?tab=readme-ov-file#hostapd
            # for details.
            "-wpad-basic-mbedtls"
            "wpad-mbedtls"
          ];
          hackExtraPackages = [ "wifi-presence" ];

          files = pkgs.runCommand "image-files" { } ''
            mkdir -p $out/etc/uci-defaults
            cat > $out/etc/uci-defaults/99-custom <<EOF

            uci -q batch << EOI
            set system.@system[0].hostname='strider'
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

            substituteInPlace $out/etc/config/ddns \
              --replace-fail "@cloudflare_api_token@" "${cloudflareApiToken}"

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
