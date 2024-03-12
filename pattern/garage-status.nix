{ config, lib, pkgs, ... }:

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

  environment.systemPackages = with pkgs; [
    (
      pkgs.writeShellApplication {
        name = "mosquitto-jfly";
        # TODO: automate publishing status of attached webcam
        text = ''
          cat ${config.age.secrets.mosquitto-password.path}
        '';
      }
    )
  ];
}
