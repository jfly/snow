{ pkgs, ytApiKeyFile, ytClientIdFile, ytClientSecretFile, mysqlPasswordFile, hostName, timeZone }:

pkgs.stdenv.mkDerivation {
  name = "gen-kodi-addon-data";
  src = ./src;
  installPhase = ''
    cp -r . $out

    substituteInPlace $out/gen-kodi-addon-data.sh \
      --replace-fail "@rsync@" ${pkgs.rsync}/bin/rsync \
      --replace-fail "@ytApiKey@" "\$(cat ${ytApiKeyFile})" \
      --replace-fail "@ytClientId@" "\$(cat ${ytClientIdFile})" \
      --replace-fail "@ytClientSecret@" "\$(cat ${ytClientSecretFile})" \
      --replace-fail "@mysqlPass@" "\$(cat ${mysqlPasswordFile})"

    substituteInPlace $out/advancedsettings.xml \
      --replace-fail "@hostName@" "${hostName}" \
      --replace-fail "@timeZone@" "${timeZone}"
  '';
}
