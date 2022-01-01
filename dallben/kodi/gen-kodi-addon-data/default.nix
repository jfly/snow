{pkgs}:

let secrets = (import ../../secrets.nix);
in
pkgs.stdenv.mkDerivation {
  name = "gen-kodi-addon-data";
  src = ./src;
  installPhase = ''
    cp -r . $out
    substituteInPlace $out/addon_data/plugin.video.youtube/api_keys.json \
      --replace "{{ YOUTUBE_API_KEY }}" "${secrets.youtube.api_key}" \
      --replace "{{ YOUTUBE_CLIENT_ID }}" "${secrets.youtube.client_id}" \
      --replace "{{ YOUTUBE_CLIENT_SECRET }}" "${secrets.youtube.client_secret}"
  '';
}
