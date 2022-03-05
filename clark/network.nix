{ pkgs, ... }:

{
  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;

  # Enable VPN
  networking.wg-quick.interfaces = {
    wg0 = {
      # Determines the IP address and subnet of the client's end of the tunnel interface.
      address = [ "10.67.182.177/32" "fc00:bbbb:bbbb:bb01::4:b6b0/128" ];
      listenPort = 51820; # to match firewall allowedUDPPorts (without this wg uses random port numbers)

      privateKey = pkgs.deage.string ''
        -----BEGIN AGE ENCRYPTED FILE-----
        YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBkSDI5dUdiekVncVFkUklj
        RjJxMm15My9UVnM4ZTlDWlNqYkpsWnpHQVM4CkwrSlliVjU2alI4aEdSNTRJWWpz
        RXY5YTFYQ2xvSnRqS2tpeDNEN01aY3cKLS0tIDMrR2ZJWmUvUXZ3QnJrTHVSenFQ
        alp6QzZXOThpallIbWdoWnB5THRwUnMK5+WrhxdmUtk1THDMbyaafiBcwwg3NrJb
        7loZpUvF/VDLef6F/JGpf4lAsr/hb9yb6xMbNnvGXwEWqqbTZMniiVIXnz8hVgyu
        u73KwA==
        -----END AGE ENCRYPTED FILE-----
      '';

      table = "vpn";

      peers = (map (server_info:
          {
            # Forward all the traffic via VPN.
            allowedIPs = [ "0.0.0.0/0" "::0/0" ];

            # Important to keep NAT tables alive.
            persistentKeepalive = 25;
          } // server_info
        )
        [
          {
            publicKey = "cI+iLB7yKEXlfb4qFfW3EWzAf6WuqiLcNMrEsd5koUs=";
            endpoint = "89.45.90.15:51820";
          }
          {
            publicKey = "nIhtsNsWRvRKYwjeD5xsZL2kBR+HS6Tw49G+5mrllhc=";
            endpoint = "89.45.90.106:51820";
          }
          {
            publicKey = "rwT05S8WXMOMUIf41yUQyZGnxGwxHOrPdAXgjEEOTx8=";
            endpoint = "89.45.90.67:51820";
          }
          {
            publicKey = "/ANLhlyoSseZlgKXQuheOiSAf+ZMNvY/eaylfEt7Y1g=";
            endpoint = "89.45.90.184:51820";
          }
          {
            publicKey = "0/G/B4slscoo2K0PZBh/o4kMHzWp1JXnsjonLKNcUwg=";
            endpoint = "89.45.90.132:51820";
          }
        ]
      );
    };
  };
}
