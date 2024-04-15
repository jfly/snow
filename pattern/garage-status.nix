{ on-air }:
{ config, lib, pkgs, ... }:

let
  on-air-pkg = on-air.packages.${config.nixpkgs.hostPlatform.system}.default;
in
{
  age.secrets.mosquitto-password = {
    owner = "jeremy";
    rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSAyalBoQ1ltK2lSMFNuN2tQ
      VFZDMFA1NUptTlE5TU40V0VpbUJLckt6cUdnCmY0NGpzZThQV3paTkNHdnFlcEZx
      dzgzeU96Y0dadTAyMHlWU1JXNUF2NU0KLS0tIGdHeE93eStvS1Npa25CWCs2YTlm
      d2ZyQnUvT1Q2RnIwREszblVzeEdnYVEK1Rwcpz88WQmMhK3fqjNLK0D669gGurys
      Ep/ulkpV153905j7eZhJWUbJRS2AlTpypXRv4w==
      -----END AGE ENCRYPTED FILE-----
    '';
  };

  systemd.user.services.on-air = {
    enable = true;
    description = "on-air";

    wantedBy = [ "location-garageman.target" ];
    partOf = [ "location-garageman.target" ];

    script = ''
      ${on-air-pkg}/bin/on-air mqtt \
        --broker mqtts://mqtt.snow.jflei.com \
        --username jfly \
        --password-file ${config.age.secrets.mosquitto-password.path} \
        --device-name ${config.networking.hostName} \
        --poll-seconds 1
    '';
    serviceConfig = {
      Type = "simple";
      Restart = "always";
    };
  };
}
