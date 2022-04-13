{ pkgs, ... }:

let
  local_subnet = "192.168.1.0/24";
  local_gateway = "192.168.1.1";
in
{
  # Hack copied from
  # https://discourse.nixos.org/t/docker-podman-network-create-nix/13569
  systemd.services."docker-network-clark" = {
    serviceConfig.Type = "oneshot";
    requiredBy = [ "docker-snow-web.service" "docker-home-assistant.service" ];
    script = ''
      export PATH=${pkgs.docker}/bin:$PATH
      docker network inspect clark > /dev/null 2>&1 || docker network create clark
    '';
  };

  # Adopted from https://maxammann.org/posts/2020/04/routing-docker-container-over-vpn/
  networking.iproute2 = {
    enable = true;
    rttablesExtraConfig = ''
      100     vpn
    '';
  };
  systemd.services."docker-network-vpn" = {
    serviceConfig.Type = "oneshot";

    requires = ["wg-quick-wg0.service"];
    requiredBy = [ "docker-vpn-test.service" ];

    script = ''
      export PATH=${pkgs.docker}/bin:$PATH
      export PATH=${pkgs.iproute2}/bin:$PATH
      export PATH=${pkgs.iptables}/bin:$PATH

      docker network inspect vpn > /dev/null 2>&1 || docker network create \
                                                              -d bridge \
                                                              -o 'com.docker.network.bridge.name'='vpn' \
                                                              --subnet=172.19.0.1/16 vpn

      # Modified from https://maxammann.org/posts/2020/04/routing-docker-container-over-vpn/
      # Ensures that traffic for the vpn docker network *only* goes through the VPN.

      # Remove any previous routes in the 'vpn' routing table
      ip rule | sed -n 's/.*\(from[ \t]*[0-9\.\/]*\).*vpn/\1/p' | while read RULE; do
        ip rule del ''${RULE}
        ip route flush table vpn
      done
      # Note, if you compare these steps to the blog post linked above, you'll
      # see that we are skipping the "Add route to the VPN endpoint" step. That's because we
      # don't need to add route to the VPN endpoint because we are not
      # configuring all traffic to go through the VPN. Instead, we're only
      # configuring traffic from the docker vpn network to go through the VPN.
      #
      # Traffic coming FROM the docker network should go though the vpn table
      ip rule add from 172.19.0.1/16 lookup vpn
      # Local traffic should go through eno1
      ip route add ${local_subnet} dev eno1 table vpn
      # Traffic to docker network should go to docker vpn network
      ip route add 172.19.0.0/16 dev vpn table vpn

      # Now make sure that traffic *only* goes over the VPN, even if the VPN is down.
      iptables -I DOCKER-USER -i vpn ! -o wg0 -j REJECT --reject-with icmp-port-unreachable
      iptables -I DOCKER-USER -i vpn -o vpn -j ACCEPT
      iptables -I DOCKER-USER -i vpn -d ${local_subnet} -j ACCEPT
      iptables -I DOCKER-USER -s ${local_subnet} -o vpn -j ACCEPT
      iptables -I DOCKER-USER -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    '';
  };

  virtualisation.oci-containers.containers = {
    snow-web = import ./snow-web { inherit pkgs; };
    home-assistant = import ./home-assistant {};
    wallabag = import ./wallabag { inherit pkgs; };
    vpn-test = import ./vpn-test {};
  };

  # Set up a kubernetes cluser with k3s
  services.k3s.enable = true;
  services.k3s.role = "server";
  environment.systemPackages = [ pkgs.k3s ];
}
