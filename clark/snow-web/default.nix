{ pkgs, ... }:

let
  nginx-conf = ./etc/nginx/nginx.conf;
  service-htpc-conf = ./etc/nginx/service-htpc.conf;
  webroot = ./webroot;

  autogen-lefqdn-entrypoint = ./autogen-lefqdn-entrypoint.sh;
  password = pkgs.deage.string ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSB4NzRNQzQ4ZVJuRGc4UWJh
    aTdDN2RnQ2lycGNxVEY2Y3dycEhBQ3U2MGk0CjJXZHlzTHV5NDJNS1g5RUFZeHov
    bGV2QWgxMHlJUnBJdHZhQVU0MGVncXcKLS0tIFdIeVFQOXN1QzJ3K2d3dVJyajRt
    bUF4emdkdjFINS9aeGJ2SU9GNjArS3MKTrHgg6oK9NIL9fJC3SeK8SB9ihvAbh6/
    4zdCCMJUPGkDEARi/HmQmQ==
    -----END AGE ENCRYPTED FILE-----
  '';
  auth-root = pkgs.writeText "nginx-auth-root" "clark:{PLAIN}${password}";
in

{
  image = "umputun/nginx-le:latest";
  entrypoint = "/custom-entrypoint.sh";
  ports = [
    "80:80"
    "443:443"
    "9090:9090"
  ];
  volumes = [
    "/mnt/media/state/snow-web/nginx/ssl:/etc/nginx/ssl"
    "${nginx-conf}:/etc/nginx/nginx.conf"
    "${service-htpc-conf}:/etc/nginx/service-htpc.conf"
    "${auth-root}:/etc/nginx/auth/root"
    "${webroot}:/webroot"
    "${autogen-lefqdn-entrypoint}:/custom-entrypoint.sh"
    "/mnt/media:/mnt/media"
  ];
  environment = {
    TZ = "America/Los_Angeles";
    LETSENCRYPT = "true";
    LE_EMAIL = "jeremyfleischman@gmail.com";
    # Note: No need to set LE_FQDN because we're doing something
    # clever. See autogen-lefqdn-entrypoint.sh script for details.
  };
  extraOptions = [
    "--network=clark"
  ];
}
