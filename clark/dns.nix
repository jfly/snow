{ ... }:

{
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = false;
    settings = {
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
