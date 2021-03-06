{ pkgs }:

let
  # Generated by following the instructions on
  # https://github.com/jdf76/plugin.video.youtube/wiki/Personal-API-Keys
  api_key = pkgs.deage.string ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSB0Qlh2aGdoTVB3S0NodDht
    ME1yTVZXdVd1TmdWVXRWVGlaOVN1alM0eldNClZMaVZHRWpIVmY3MjFLNzRhdTlF
    dHhwajNmQ3V3OEJoVWE0UENYZFBzcW8KLS0tIGdZQ1Iyc2UvUDEweGhNeTdXNWpX
    WExNcXEwbHM0QkU5YmxGazBSZUl1RFkKGqKAcgUqRYI0fHjXXN3QZ5KrO6mMRTOo
    wOXTjOEJVq8iLou6T1pZmKzNSD0uOkzllpf4si/by78z6FwNvtOslTRhzlvNrVI=
    -----END AGE ENCRYPTED FILE-----
  '';
  client_id = pkgs.deage.string ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSB5eU1kVGxKWFNVcnFVODkv
    YnpBZ2hyRUhzZFd6NGQyYWVZUjV4dXJsVEdzClA2RGZwQnVUZ2ZWVEw5a295TUdz
    ZDA3b1FDQzJtNGpWS0lrTjJ1M3JHeE0KLS0tIGtLcytWblZtZWdMTXZ6dWlPTUhI
    UFF3SFJsRXFXMzM4aHkrVVNPSThYamsK+b60QUiLQOEj8w2HOGDkgkwrOqBT40TF
    /ynhG+WNyoLFRhWGeSqpSR8HUtrlvU1w+LL7MaZkbg4r5ifu3pYk3laWcn2JHfIT
    DI4Y0HWMLSiZbed5oDIZo+upilWGYDYcrPNXj4b2ESU=
    -----END AGE ENCRYPTED FILE-----
  '';
  client_secret = pkgs.deage.string ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBUU0tvcWVteSswWERRSHVi
    QTU1SGdUUmVnOEJZZ1NCYVRVcE1jSnhlajBFCmZzTzdnQjRLNEF4TVJySU00Qlh0
    bS9VRHpFV2EzMG9IWXpET1FCYURIVHcKLS0tIGQxL0FxR2tWWEJJVW5uaWE0RFZF
    RzIya1ppbXpvVjVrOXdPQXhFOUV5RUkKwGLVZnmlIK9APmOjFRla9buFg7hmcfti
    hCh5mTe29yYc1gKmnEpUODa4nfu9+/ilIHthAv9Tn5k=
    -----END AGE ENCRYPTED FILE-----
  '';
in
pkgs.stdenv.mkDerivation {
  name = "gen-kodi-addon-data";
  src = ./src;
  installPhase = ''
    cp -r . $out
    substituteInPlace $out/addon_data/plugin.video.youtube/api_keys.json \
      --replace "{{ YOUTUBE_API_KEY }}" "${api_key}" \
      --replace "{{ YOUTUBE_CLIENT_ID }}" "${client_id}" \
      --replace "{{ YOUTUBE_CLIENT_SECRET }}" "${client_secret}"
  '';
}
