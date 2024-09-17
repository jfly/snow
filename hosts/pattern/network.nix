{ config, pkgs, ... }:

let
  buildNmConnectionDerivedSecret =
    {
      ssid,
      uuid,
      psk,
    }:
    {
      mode = "0400"; # readonly (user)
      script = pkgs.writeShellScript "gen-nm-connection" ''
        echo "[connection]
        id=${ssid}
        uuid=${uuid}
        type=wifi

        [wifi]
        mode=infrastructure
        ssid=${ssid}

        [wifi-security]
        auth-alg=open
        key-mgmt=wpa-psk
        psk=$(cat ${psk.path})

        [ipv4]
        method=auto

        [ipv6]
        addr-gen-mode=stable-privacy
        method=auto

        [proxy]"
      '';
    };
in
{

  networking.hostName = "pattern";
  networking.networkmanager.enable = true;

  age.secrets.hen-wen-passphrase = {
    rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBqZWN0MGw0VVVvS256b0U4
      ZDEzOFZFUlRkSDBoWmRlSmVtYUpHb0xudGtrClh5b0FlWEpYYm16THhhZnNJRUhp
      cFRkNnhmMUNjdHJkTGJNdFE3c2xGNWMKLS0tIGp1UEpQdlBvQkpQZEpFdGZsTm5N
      ek1NVmFIWTRSK1VlOEtyUFdVbys0YmMK25hJ+9tlvsNFx9bv4eFKf4o6bEsEwd4z
      cKEFol1r83HsP3z9puR5+mAyrFo=
      -----END AGE ENCRYPTED FILE-----
    '';
  };
  age.rooter.derivedSecrets."/etc/NetworkManager/system-connections/Hen Wen.nmconnection" =
    buildNmConnectionDerivedSecret
      {
        ssid = "Hen Wen";
        uuid = "9ff99b03-b1db-4c00-ab90-1a0e5b1fdf83";
        psk = config.age.secrets.hen-wen-passphrase;
      };

  age.secrets.jay-fly-phone-passphrase = {
    rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBTN0JkSVZZMC82WnU2MVNs
      UTZQK3owM0QveEVKSXVRRUc4c3BqWUVpb0hzCmNWbnU0bmR2dFppMHVnakRPY2Rt
      eHJiKzVDTUMvcHl6d3d2MWVxUjR3WFUKLS0tIEtBMWM2T2FsZ0FwM0hqb1RkV3l5
      Q0cxeGlodVZmMkRaQTVzVzlGNmhTcWsKMR3Sq9py5K7SCM85oy+rKjMnvcvjLc+8
      7zmRlPZGK2pFI9kJJ611lbSJ
      -----END AGE ENCRYPTED FILE-----
    '';
  };
  age.rooter.derivedSecrets."/etc/NetworkManager/system-connections/jay fly phone.nmconnection" =
    buildNmConnectionDerivedSecret
      {
        ssid = "jay fly phone";
        uuid = "5736556a-cd3e-4588-a049-6cb3362c48e7";
        psk = config.age.secrets.jay-fly-phone-passphrase;
      };

  age.secrets.cal-5g-passphrase = {
    rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBubjF5N01MRW5rZU9XU3Ba
      UDNnc3BTLy8vRForUHpLa1V1RnZ4MzhYcjNrCjEzQnZxUUYzNFluOEpEWGJnRERr
      cEdJZW1TN2lRclNPNzdIU0NRZDdrajAKLS0tIHA3MVRVYnR2TTl5R3g3SjBuQnVS
      VTludnczbnFJREZWcGNFcDRYSWl5ZlkKGEb1fFOZUXm8ZoBMDkB39CTZbjfEpUJA
      Mq8rFAt6gOW1Ct9LrOCpPgLtRCJBBA==
      -----END AGE ENCRYPTED FILE-----
    '';
  };
  age.rooter.derivedSecrets."/etc/NetworkManager/system-connections/Cal 5g.nmconnection" =
    buildNmConnectionDerivedSecret
      {
        ssid = "Cal 5g";
        uuid = "c65efd03-2c3c-4e6e-87c5-a6e1530da250";
        psk = config.age.secrets.cal-5g-passphrase;
      };

  # Let NetworkManager handle everything.
  networking.useDHCP = false;
  # Disable the firewall. I'm not used to having one, and we're behind a NAT anyways...
  networking.firewall.enable = false;

  # Disable sshd.
  services.openssh = {
    enable = false;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
}
