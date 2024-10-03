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
7. Finally, you will be asked to "Select the libraries to add". Add "All"
   libraries. Note that it's non-obvious how to select things! See
   <https://github.com/jellyfin/jellyfin-kodi/issues/923#issuecomment-2387278578>
   for details.
   I also found that this didn't work on the first try and I had to do it
   again from the addon. Weird.
   To force a refresh, go to Addons > Jellyfin > Manage libraries > Update libraries > Select "All"
   When you get it right, there will be a very
   obvious progress bar at the top right of the screen.
