{ pkgs, ... }:

let
  nginx-conf = ./etc/nginx/nginx.conf;
  nginx-conf-d = ./etc/nginx/conf.d;
  webroot = ./webroot;
in

{
  image = "nginx:latest";
  ports = [
    "8080:80"
  ];
  volumes = [
    "${nginx-conf}:/etc/nginx/nginx.conf"
    "${nginx-conf-d}:/etc/nginx/conf.d"
    "${webroot}:/webroot"
    "/mnt/media:/mnt/media"
  ];
  environment = {
    TZ = "America/Los_Angeles";
  };
  extraOptions = [
    "--network=clark"
  ];
}
