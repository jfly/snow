{ pkgs, config }:

let
  mysqlPassword = pkgs.deage.string ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBzT2ZSam0yaTdWOEVZajUr
    ZWpGRnM3Qm5pdXVFK0xJVWFKWkM1Sk5sR1ZRCm8rRkhRaHhUUTg0aHQ2cVpxUk1s
    R0c1NHJWcFVrOWE0ZTRpazFlNU11ZTgKLS0tIFZUSXh2MEpwSXdXZWRXWlBIKzl3
    VGF0MTNMbU9OemFGdWkvdEVhOE5CYkUKkWljWikH8BKbUzosyhQ9gwBc7L8qoaHj
    ECZiuKMrOlfbWq+6/eI8mtEs/MP9U7E=
    -----END AGE ENCRYPTED FILE-----
  '';
in
pkgs.kodiPackages.toKodiAddon (pkgs.stdenv.mkDerivation {
  name = "media";
  src = ./src;

  installPhase = ''
    cp -r . $out
    substituteInPlace $out/share/kodi/system/advancedsettings.xml \
      --replace "@mysql_pass@" "${mysqlPassword}" \
      --replace "@host_name@" "${config.networking.hostName}" \
      --replace "@time_zone@" "${config.time.timeZone}"
  '';
})
