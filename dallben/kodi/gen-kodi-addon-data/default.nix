{ pkgs, rsync, ytApiKeyFile, ytClientIdFile, ytClientSecretFile, mysqlPasswordFile, hostName, timeZone }:

pkgs.stdenv.mkDerivation {
  name = "gen-kodi-addon-data";
  src = ./src;
  installPhase = ''
    cp -r . $out

    substituteInPlace $out/gen-kodi-addon-data.sh \
      --replace "@rsync@" ${pkgs.rsync}/bin/rsync \
      --replace "@ytApiKey@" "\$(cat ${ytApiKeyFile})" \
      --replace "@ytClientId@" "\$(cat ${ytClientIdFile})" \
      --replace "@ytClientSecret@" "\$(cat ${ytClientSecretFile})" \
      --replace "@mysqlPass@" "\$(cat ${mysqlPasswordFile})"

    substituteInPlace $out/advancedsettings.xml \
      --replace "@hostName@" "${hostName}" \
      --replace "@timeZone@" "${timeZone}"
  '';
}
