{
  # Restart if systemd isn't health enough to ping the hardware every 15 seconds.
  # See https://0pointer.de/blog/projects/watchdog.html
  #
  # I'm not clear on how helpful this will be at recovering from lockups. If
  # it's useful, consider moving this to a shared place for all servers.
  systemd.settings.Manager = {
    RuntimeWatchdogSec = "30s";
  };
}
