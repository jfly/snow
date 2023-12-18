{ config, ... }:

{
  age.secrets.wifi-secrets.rooterEncrypted = ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSArZXhyRlFpQnlIUTZFUFBw
    NUNZOWZ0RlNsQnBCMVplUHZ6VDNpMCtKWmhjCk0xWS9TL3pjREZBUkVWcWlrUWt1
    NGluVG5Wc0dvSEg3ZllValpxQ2N5alkKLS0tIDJGclYvZ29vRkZYc2NzZm83YVVu
    RUJnb1ZFWkVjdDZpMUVUbUZobXBqeUkKEiSbwyvzMM2Jc7d/8xj2AFM1q/nZWGjD
    DUvHHTPkjgpsAbWx528Wzqp39Ei8FJFiGizJKMbHOsmJhg==
    -----END AGE ENCRYPTED FILE-----
  '';

  # Set up networking.
  hardware.enableRedistributableFirmware = true; # required for the wireless firmware
  networking = {
    hostName = "kent";
    wireless = {
      enable = true;
      interfaces = [ "wlan0" ];
      environmentFile = config.age.secrets.wifi-secrets.path;

      networks."Hen Wen".psk = "@WIFI_PASSWORD@";
    };
  };
}
