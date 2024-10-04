# kodi-colusita

This doesn't fully configure Kodi, because the Jellyfin plugin has a number of
things to do on first boot. Here's what you need to do to get it working:

1. (If necessary) Add a new Jellyfin user for whatever device you're
   configuring: <https://jellyfin.snow.jflei.com/web/#/dashboard/users>
   - Do NOT allow media deletion!
2. Start up Kodi.
3. It should ask if you want to enable Jellyfin. Say yes.
4. A "Select main server" modal will pop up. Fill in "jellyfin.snow.jflei.com"
5. Fill in the username and password from step 1.
6. When asked about playback mode, select "Add-on".
7. Addons > Jellyfin > Settings > Advanced > Startup delay (in seconds): set this to 5.
   Why the hack? This is because Kodi often starts Jellyfin up before the
   network has finished initialzing. Ideally Jellyfin would change to be more
   resilient to that. For more details:
     - <https://github.com/jellyfin/jellyfin-kodi/issues/343>: mentions the
       startup delay workaround we're using
     - <https://systemd.io/NETWORK_ONLINE>: systemd has a workaround for
       not-very-robust clients, but it doesn't work due to a mix of reasons:
       1. NixOS's default network configuration (so-called "scripted
          networking") doesn't register a "wait" service. It seems like we
          could fix this by using either systemd-networkd or NetworkManager, but
          I tried that and...
       2. systemd-networkd's definition of network-online.target doesn't
          actually guarantee that DNS is up. I'm still seeing Jellyfin fail on
          boot.
7. Finally, you will be asked to "Select the libraries to add". Add "All"
   libraries. Note that it's non-obvious how to select things! See
   <https://github.com/jellyfin/jellyfin-kodi/issues/923#issuecomment-2387278578>
   for details.
   I also found that this didn't work on the first try and I had to do it
   again from the addon. Weird.
   To force a refresh, go to Addons > Jellyfin > Manage libraries > Update libraries > Select "All"
   When you get it right, there will be a very obvious progress bar at the top
   right of the screen.
