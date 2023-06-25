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

        profiles = openwrt-imagebuilder.lib.profiles {
          inherit pkgs;
          release = "22.03.5";
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

        # TODO: share with other routers
        wifiPassword = pkgs.deage.string ''
          -----BEGIN AGE ENCRYPTED FILE-----
          YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBiMjFGNTFPYTVXcWIyeW4x
          M0VuOURsQmZJbXE0QWY1RjNmVnp5VjBKTlRZCllsYitvWWlVY0N0U3hXN1lVTmJO
          Z3ljMHRrYkJVWHd3cU8vSU5MSUwxV00KLS0tIEVuU1p4eFRKTkxNZkk3NzZQdmds
          WmhzT2NoUEJiNCtTTUNmRGU4Qjh6eU0K4xTdrdazTIOpP9vmdaigLMmHfSfEEnSu
          uq0FTh+oKCJ00kRgWVAYWwlCP+A=
          -----END AGE ENCRYPTED FILE-----
        '';

        image-no-version = profiles.identifyProfile "linksys_e8450-ubi" // {
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
          ];

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
              --replace "@cloudflare_api_token@" "${cloudflareApiToken}"

            substituteInPlace $out/etc/config/wireless \
              --replace "@wifi_password@" "${wifiPassword}"
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
