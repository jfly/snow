{ pkgs, lib, openwrt-imagebuilder }:

{ hostname, profileName, config-files, rootPassword, mqttPassword, dumbap }:

let
  inherit (pkgs.lib)
    splitString
    optionals
    ;

  release = "23.05.2";
  profiles = openwrt-imagebuilder.lib.profiles {
    inherit pkgs release;
  };
  profile = profiles.identifyProfile profileName;

  hashes = import "${openwrt-imagebuilder}/hashes/23.05.2.nix";

  packagesArch = hashes.targets.${profile.target}.${profile.variant}.packagesArch;

  config = pkgs.stdenv.mkDerivation {
    name = "openwrt-config-files";
    src = config-files;
    installPhase = ''
      mkdir -p $out
      cp -r * $out/
    '';
  };

  wifi = {
    home = {
      password = pkgs.deage.string ''
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
      password = pkgs.deage.string ''
        -----BEGIN AGE ENCRYPTED FILE-----
        YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBObmJ5Q1NoOFkxSnFPdlYz
        bjAxVzZWd1VvbXBsOWtkRklzVUtPVnNIdkNzCmJSdlBXSmNGc3JRbm93VXBWaHlF
        V1pPZEMvVmgwUXdoaVNDM2hENmVBQUEKLS0tIDNEdENXOE1SQUhpaWdMR0htVlc4
        QUNmd2ZGWVVLQnZ5bFBEQUgvOXZlSDAK8byIeNYA/+PhYh/a9Y3kZsRpSx42wFFY
        W59sGFTSHLPDqALbQLqu2ywq
        -----END AGE ENCRYPTED FILE-----
      '';
    };
  };

  cloudflareApiToken = pkgs.deage.string ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSArQjNRYWxLdyszY0dBRmNL
    RmJiY3R1NTk1TVcvWDlvVVAwM1luNzZvN2cwCnFrNjRwMDBONFlGTmZ4aXBLV0Rj
    UElRc2tOL0Zlc1VRRVpmOXZwMU1HSzgKLS0tIHNVMVhKU3EzN0x5NlVkN0J2b1NL
    M2tkb3BiVUJ0SmRwZ3JtS1c0WmNDeVkKd6aIxcBae2D9laj8XgGYow6dUmb2GJQk
    iIrz94V8b59mPw9d8plEQdCBN4L3auY9H2EJQ8ltPMiF4o5Pl2cWT/G5RlRjda+d
    -----END AGE ENCRYPTED FILE-----
  '';

  identities = import ../shared/identities.nix;

  #<<<
  maybeUpdateDdns = if dumbap then "" else ''

    substituteInPlace $out/etc/config/ddns \
      --replace-fail "@cloudflare_api_token@" "${cloudflareApiToken}"
  '';
  #<<<

  # Urg, right now installing custom packages is a *pain*. See
  # https://github.com/astro/nix-openwrt-imagebuilder/issues/38 for a
  # feature request to make this easier to deal with.
  wifi-presence-by-arch = {
    aarch64_cortex-a53 = {
      file = pkgs.fetchurl {
        url = "https://github.com/awilliams/wifi-presence/releases/download/v0.3.0/wifi-presence_0.3.0-1_aarch64_cortex-a53.ipk";
        sha256 = "sha256-yN2wDs723HGfmEKS4x1QQwCv4938edRQTJaVGwdQe7Y=";
      };
      filename = "wifi-presence_0.3.0-1_aarch64_cortex-a53.ipk";
    };

    mipsel_24kc = {
      file = pkgs.fetchurl {
        url = "https://github.com/awilliams/wifi-presence/releases/download/v0.3.0/wifi-presence_0.3.0-1_mipsel_24kc.ipk";
        sha256 = "sha256-kCPU9q8mc+qKt6/BMgBfGoO3ZqvhZRFsmBkuZTTRou4=";
      };
      filename = "wifi-presence_0.3.0-1_mipsel_24kc.ipk";
    };
  };
  wifi-presence = wifi-presence-by-arch.${packagesArch};
  built-no-version = (openwrt-imagebuilder.lib.build (profile // {
    packages =
      if dumbap then [
        "luci"
        # Remove the stripped down version of hostapd in favor of the full
        # version. This is necessary for awilliams/wifi-presence. See
        # https://github.com/awilliams/wifi-presence?tab=readme-ov-file#hostapd
        # for details.
        "-wpad-basic-mbedtls"
        "wpad-mbedtls"
      ] else [
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
      ${maybeUpdateDdns}
      substituteInPlace $out/etc/config/wireless \
        --replace-fail "@wifi_password@" "${wifi.home.password}" \
        --replace-fail "@wifi_iot_password@" "${wifi.iot.password}"

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
  nix-build-version = builtins.head (splitString "-" (last (splitString "/" built-no-version.outPath)));

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

built-with-version
