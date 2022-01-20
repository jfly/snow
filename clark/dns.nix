{ ... }:

{
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = false;
    extraConfig = ''
      no-resolv

      # Dropbox stuff
      server=/www.dropbox.com/8.8.8.8
      server=/dropbox.com/8.8.8.8
      server=/cfl.dropboxstatic.com/8.8.8.8
      # Google stuff
      server=/accounts.google.com/8.8.8.8
      server=/drive.google.com/8.8.8.8
      server=/docs.google.com/8.8.8.8
      server=/fonts.gstatic.com/8.8.8.8
      server=/fonts.googleapis.com/8.8.8.8
      # Discord stuff
      server=/discord.com/8.8.8.8
      server=/discord.gg/8.8.8.8
      server=/discordapp.com/8.8.8.8
      server=/discordapp.net/8.8.8.8
      # Airtable
      server=/airtable.com/8.8.8.8
      # Dictionary
      server=/www.merriam-webster.com/8.8.8.8
    '';
  };
}
