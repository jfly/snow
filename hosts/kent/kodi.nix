{ config, pkgs, ... }:

{
  imports = [
    # TODO: accesss in a less weird way, perhaps as module args threaded in via
    # `specialArgs`? See
    # https://github.com/BirdeeHub/birdeeSystems/blob/8e5538d66690234f5bccd1c2a9211858b933e466/flake.nix#L304
    # for one such example.
    ../../modules/kodi-colusita
  ];

  networking.firewall.allowedTCPPorts = [
    8080 # Web server
    9090 # JSON/RPC
  ];
  networking.firewall.allowedUDPPorts = [
    9777 # Event Server
  ];

  services.kodi-colusita = {
    enable = true;
    sshIdentityPath = config.age.secrets.colusita-media-identity.path;
    startOnBoot = true;
  };

  age.secrets.colusita-media-identity = {
    # kent.kodi
    rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBBc1VnbjByYUFWYlNiVW9L
      ZndwbkVrQTJEUHFlb01YbWM0RGVpTGpDeTJFCnl1WExQeVF6bTRpTnhWNk9Zd3U3
      OUxJNHU4aS9MZFJRbEc1M1MweWpJbmMKLS0tIE11aDJqU0NzS1J2QXBuOU5wYzVI
      R0d2VWJERWIwMkxVZlpHcU9VWkowTUkKb7XW00qwe14Idws3E5JO3yaBnIYO0bIT
      8vFFhARJidiun4/zazfLwyyMmNJiXTwQ8w4KS9tsRNo2RUmr2tJsybyIT0qVgsQe
      PQN6fNevQEbHmeDullDH1dfoB+YzSuRUidjzgxk+aaGANLSEt2BdLTs35TIFNk5A
      /SuCLOaP2CRUoBvEDqylzDW7u9bc3XAeG4/gfKArIfIljqMe0mk5mZpCRwLLs4kN
      hO/jvW4Ft0ffu2h5cbpgPOLAAr0Ev6BkfrC1OCt7ARrIK4fi0Occ37Pu2p0CScJA
      yA7MEgPwMgBi5z/rcHshFHd2/CnJh8fkjx/NdeZ4Y3E65jGZyc6lGWVesL7mvZYU
      1D9ldaAVbGfPadQUg4H/JdBcTbjdkLOkBH6n3pe281CouEvMe9DHUYPLe1oAH95s
      4Gu921dtL+Kpxe156Bi98S6kciQN366bfagOHVugCHkL099BzFqhHGPGNsCyxEth
      2PEeuLhNxxXL/DqtsnTWwITDG0RobxU8jC2hqwNEBvFNQc2LoiALUwR5joVyEI+b
      r9G3J0FVfCtDTzfeUS7NSdav7W/af1jC6z0IjA1fxT2bAOCx+FDJr8o3MA==
      -----END AGE ENCRYPTED FILE-----
    '';
  };
}
