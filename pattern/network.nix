{ pkgs, ... }:

let
  buildNmConnection = connection: ''
    [connection]
    id=${connection.ssid}
    uuid=${connection.uuid}
    type=wifi

    [wifi]
    mode=infrastructure
    ssid=${connection.ssid}

    [wifi-security]
    auth-alg=open
    key-mgmt=wpa-psk
    psk=${connection.psk}

    [ipv4]
    method=auto

    [ipv6]
    addr-gen-mode=stable-privacy
    method=auto

    [proxy]
  '';
in
{
  networking.hostName = "pattern";
  networking.networkmanager.enable = true;
  environment.etc."NetworkManager/system-connections/Hen Wen.nmconnection" = {
    mode = "0400"; # readonly (user)
    text = buildNmConnection {
      ssid = "Hen Wen";
      uuid = "9ff99b03-b1db-4c00-ab90-1a0e5b1fdf83";
      psk = pkgs.deage.string ''
        -----BEGIN AGE ENCRYPTED FILE-----
        YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBqZWN0MGw0VVVvS256b0U4
        ZDEzOFZFUlRkSDBoWmRlSmVtYUpHb0xudGtrClh5b0FlWEpYYm16THhhZnNJRUhp
        cFRkNnhmMUNjdHJkTGJNdFE3c2xGNWMKLS0tIGp1UEpQdlBvQkpQZEpFdGZsTm5N
        ek1NVmFIWTRSK1VlOEtyUFdVbys0YmMK25hJ+9tlvsNFx9bv4eFKf4o6bEsEwd4z
        cKEFol1r83HsP3z9puR5+mAyrFo=
        -----END AGE ENCRYPTED FILE-----
      '';
    };
  };
  environment.etc."NetworkManager/system-connections/jay fly phone.nmconnection" = {
    mode = "0400"; # readonly (user)
    text = buildNmConnection {
      ssid = "jay fly phone";
      uuid = "5736556a-cd3e-4588-a049-6cb3362c48e7";
      psk = pkgs.deage.string ''
        -----BEGIN AGE ENCRYPTED FILE-----
        YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBTN0JkSVZZMC82WnU2MVNs
        UTZQK3owM0QveEVKSXVRRUc4c3BqWUVpb0hzCmNWbnU0bmR2dFppMHVnakRPY2Rt
        eHJiKzVDTUMvcHl6d3d2MWVxUjR3WFUKLS0tIEtBMWM2T2FsZ0FwM0hqb1RkV3l5
        Q0cxeGlodVZmMkRaQTVzVzlGNmhTcWsKMR3Sq9py5K7SCM85oy+rKjMnvcvjLc+8
        7zmRlPZGK2pFI9kJJ611lbSJ
        -----END AGE ENCRYPTED FILE-----
      '';
    };
  };

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  # Disable the firewall. I'm not used to having one, and we're behind a NAT anyways...
  networking.firewall.enable = false;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    permitRootLogin = "no";
  };
}
