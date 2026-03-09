let
  port = 7654;
in
{
  services.tang = {
    enable = true;
    listenStream = [ (toString port) ];
    ipAddressAllow = [
      "localhost"
    ];
  };

  snow.services.tang.proxyPass = "http://localhost:${toString port}";
}
