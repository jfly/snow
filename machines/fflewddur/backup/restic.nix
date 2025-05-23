let
  resticPort = 8000;
in
{
  # Enable the Restic REST server.
  services.restic.server = {
    enable = true;
    listenAddress = toString resticPort;
    dataDir = "/mnt/bay/restic";
    # We're not (currently) requiring authentication to speak to the rest
    # server. This allows us to avoid futzing with HTTPS and certificates.
    # However, it does mean that anyone on the network can talk to this server
    # (we don't expose port 8000 to the internet), so to remove the risk of
    # folks deleting backups, we run the server in "append only" mode.
    # From https://github.com/restic/rest-server?tab=readme-ov-file#why-use-rest-server:
    #   > the REST backend has better performance, especially so if you can skip
    #   > additional crypto overhead by using plain HTTP transport
    appendOnly = true;
    extraFlags = [
      # See comment above `appendOnly` for why this is safe.
      "--no-auth"
    ];
  };

  networking.firewall.allowedTCPPorts = [ resticPort ];
}
