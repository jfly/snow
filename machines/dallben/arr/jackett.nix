{ pkgs, config, ... }:
let
  port = config.services.jackett.port;
in
{
  services.jackett.enable = true;
  services.jackett.package = pkgs.jackett.overrideAttrs (oldAttrs: {
    patches = oldAttrs.patches or [ ] ++ [
      # Fix for <https://github.com/Jackett/Jackett/issues/16347>
      (pkgs.fetchpatch {
        name = "thepiratebay: make files optional";
        url = "https://patch-diff.githubusercontent.com/raw/Jackett/Jackett/pull/16346.patch";
        hash = "sha256-g0SQT/fgalDa2AKvG+UuceDTsL0wnhHdbSX0G4apHeQ=";
      })
    ];
  });

  snow.services.jackett.proxyPass = "http://${config.vpnNamespaces.wg.namespaceAddress}:${toString port}";

  systemd.services.jackett = {
    vpnConfinement = {
      enable = true;
      vpnNamespace = "wg";
    };
  };

  vpnNamespaces.wg.portMappings = [
    {
      from = port;
      to = port;
      protocol = "tcp";
    }
  ];

  snow.backup.paths = [
    config.services.jackett.dataDir
  ];
}
