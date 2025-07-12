{ inputs, flake, ... }:

{
  pkgs,
  hostname,
  profileName,
  config-files,
  config-template-values-by-file ? { },
  rootPassword,
  mqtt,
  dumbap,
}:

let
  inherit (pkgs.lib)
    attrsToList
    concatStringsSep
    optionals
    splitString
    ;
  inherit (inputs)
    openwrt-imagebuilder
    ;
  inherit (flake.lib)
    deage
    identities
    ;

  release = "24.10.2";
  profiles = openwrt-imagebuilder.lib.profiles {
    inherit pkgs release;
  };
  profile = profiles.identifyProfile profileName;

  # Substitutions for our final config. Yes, this leaks secrets to the store :cry:.
  # We could potentially clean this up if we were willing to generate UCI ourselves.
  # See
  # https://openwrt.org/docs/guide-user/base-system/uci#uci_dataobject_model,
  # and some prior art here:
  # https://discourse.nixos.org/t/example-on-how-to-configure-openwrt-with-nixos-modules/18942
  # However, I think it would be more interesting to explore
  # https://www.liminix.org/ as an alternative to all of this.
  final-template-values-by-file = {
    "/etc/config/system" = {
      "@hostname@" = hostname;
    };
    "/etc/config/wireless" = {
      "@wifi_password@" = wifi.home.password;
      "@wifi_iot_password@" = wifi.iot.password;
      "@wifi_guest_password@" = wifi.guest.password;
    };
    "/etc/config/wifi-presence" = {
      "@mqtt_password@" = mqtt.password;
      "@mqtt_username@" = mqtt.username;
    };
    "/etc/dropbear/authorized_keys" = {
      "@authorized_key@" = identities.jfly;
    };
  } // config-template-values-by-file;

  config = pkgs.stdenv.mkDerivation {
    name = "openwrt-config-files";
    src = config-files;
    installPhase =
      let
        toSubtitutions =
          subtitutionMap:
          map (param: "--replace-fail '${param.name}' '${param.value}'") (attrsToList subtitutionMap);
      in
      concatStringsSep "\n" (
        [
          "mkdir -p $out"
          "cp -r * $out/"
        ]
        ++ map (
          param: "substituteInPlace $out/${param.name} ${concatStringsSep " " (toSubtitutions param.value)}"
        ) (attrsToList final-template-values-by-file)
      );
  };

  wifi = {
    home = {
      password = deage.impureString ''
        -----BEGIN AGE ENCRYPTED FILE-----
        YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBiMjFGNTFPYTVXcWIyeW4x
        M0VuOURsQmZJbXE0QWY1RjNmVnp5VjBKTlRZCllsYitvWWlVY0N0U3hXN1lVTmJO
        Z3ljMHRrYkJVWHd3cU8vSU5MSUwxV00KLS0tIEVuU1p4eFRKTkxNZkk3NzZQdmds
        WmhzT2NoUEJiNCtTTUNmRGU4Qjh6eU0K4xTdrdazTIOpP9vmdaigLMmHfSfEEnSu
        uq0FTh+oKCJ00kRgWVAYWwlCP+A=
        -----END AGE ENCRYPTED FILE-----
      '';
    };
    iot = {
      password = deage.impureString ''
        -----BEGIN AGE ENCRYPTED FILE-----
        YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBObmJ5Q1NoOFkxSnFPdlYz
        bjAxVzZWd1VvbXBsOWtkRklzVUtPVnNIdkNzCmJSdlBXSmNGc3JRbm93VXBWaHlF
        V1pPZEMvVmgwUXdoaVNDM2hENmVBQUEKLS0tIDNEdENXOE1SQUhpaWdMR0htVlc4
        QUNmd2ZGWVVLQnZ5bFBEQUgvOXZlSDAK8byIeNYA/+PhYh/a9Y3kZsRpSx42wFFY
        W59sGFTSHLPDqALbQLqu2ywq
        -----END AGE ENCRYPTED FILE-----
      '';
    };
    guest = {
      password = deage.impureString ''
        -----BEGIN AGE ENCRYPTED FILE-----
        YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSByQnRuMHdPTkUvZmdMM1J0
        RkwwdXJhVmlTbFREM3QvL3U4em1RYmJzNHo0CjcyeWRoN0JnV3Z0RXpMZjRCMjUz
        OHNLSHBncUREMndLcm1mK0ZNVkFNMUEKLS0tIEM5Sk93YnA5WlJubWZDTFBPM1BU
        RlJrbGtmUlRGZFRoVlhVZFN2aitEaGsKjMnt3ttGO+Lgz180DcxNS9vZEFB/wtHy
        Jq/Bi7Qw3GTuBxdECM2WL2JzPSo=
        -----END AGE ENCRYPTED FILE-----
      '';
    };
  };

  # Somehow these variables ended up unreferenced? I'm very confused how
  # `wifi-presence` is actually getting installed on our routers.
  # TODO: Figure this out when documenting how to do custom packages
  # (https://github.com/astro/nix-openwrt-imagebuilder/issues/38)
  # hashes = import "${openwrt-imagebuilder}/hashes/${release}.nix";
  # packagesArch = hashes.targets.${profile.target}.${profile.variant}.packagesArch;
  # wifi-presence-by-arch = {
  #   aarch64_cortex-a53 = {
  #     file = pkgs.fetchurl {
  #       url = "https://github.com/awilliams/wifi-presence/releases/download/v0.3.0/wifi-presence_0.3.0-1_aarch64_cortex-a53.ipk";
  #       hash = "sha256-yN2wDs723HGfmEKS4x1QQwCv4938edRQTJaVGwdQe7Y=";
  #     };
  #     filename = "wifi-presence_0.3.0-1_aarch64_cortex-a53.ipk";
  #   };

  #   mipsel_24kc = {
  #     file = pkgs.fetchurl {
  #       url = "https://github.com/awilliams/wifi-presence/releases/download/v0.3.0/wifi-presence_0.3.0-1_mipsel_24kc.ipk";
  #       hash = "sha256-kCPU9q8mc+qKt6/BMgBfGoO3ZqvhZRFsmBkuZTTRou4=";
  #     };
  #     filename = "wifi-presence_0.3.0-1_mipsel_24kc.ipk";
  #   };
  # };
  # wifi-presence = wifi-presence-by-arch.${packagesArch};
  built-no-version = (
    openwrt-imagebuilder.lib.build (
      profile
      // {
        packages =
          [
            "luci"
            # Remove the stripped down version of hostapd in favor of the full
            # version. This is necessary for awilliams/wifi-presence. See
            # https://github.com/awilliams/wifi-presence?tab=readme-ov-file#hostapd
            # for details.
            "-wpad-basic-mbedtls"
            "wpad-mbedtls"
            "wifi-presence"
          ]
          ++ (
            if dumbap then
              [ ]
            else
              [
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
                # Necessary for a hack to request multiple /64 prefixes from AT&T
                # https://openwrt.org/docs/guide-user/network/wan/isp-configurations#fiber
                "kmod-macvlan"
              ]
          );

        # Step 11 of https://openwrt.org/docs/guide-user/network/wifi/dumbap:
        # "To save resources on the wireless AP router, disable some now unneeded services"
        disabledServices = optionals dumbap [
          "firewall"
          "dnsmasq"
          "odhcpd"
        ];

        files = pkgs.runCommand "image-files" { } ''
          mkdir -p $out/etc/uci-defaults
          cat > $out/etc/uci-defaults/99-custom <<EOF

          uci -q batch << EOI
          set system.@system[0].hostname='${hostname}'
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
        '';
      }
    )
  );

  last = l: builtins.elemAt l (builtins.length l - 1);
  nix-build-version = builtins.head (
    splitString "-" (last (splitString "/" built-no-version.outPath))
  );

  built-with-version = built-no-version.overrideAttrs (
    finalAttrs: prevAttrs: {
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
    }
  );
in

built-with-version
