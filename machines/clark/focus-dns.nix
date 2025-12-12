{
  # TODO: is this still needed? if so, we can restrict it to the overlay network?
  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedTCPPorts = [ 53 ];

  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = false;
    settings = {
      # Bind on all interfaces as they come and go. This is important for
      # docker, as the docker0 interface appears at some point asynchronously
      # when booting up.
      # It's important for dnsmasq to bind on specific interfaces, because
      # otherwise it will try to bind to a wildcard address, which conflicts
      # with the 127.0.0.54 that systemd-resolved listens on.
      bind-dynamic = true;

      no-resolv = true;
      server = [
        # Dropbox stuff
        "/www.dropbox.com/8.8.8.8"
        "/dropbox.com/8.8.8.8"
        "/cfl.dropboxstatic.com/8.8.8.8"
        # Google stuff
        "/accounts.google.com/8.8.8.8"
        "/drive.google.com/8.8.8.8"
        "/docs.google.com/8.8.8.8"
        "/fonts.gstatic.com/8.8.8.8"
        "/fonts.googleapis.com/8.8.8.8"
        # Discord stuff
        "/discord.com/8.8.8.8"
        "/discord.gg/8.8.8.8"
        "/discordapp.com/8.8.8.8"
        "/discordapp.net/8.8.8.8"
        # Airtable
        "/airtable.com/8.8.8.8"
        # Dictionary
        "/www.merriam-webster.com/8.8.8.8"
      ];
    };
  };
}
