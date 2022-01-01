{ lib, buildKodiAddon, fetchFromGitHub, inputstream-adaptive, arrow, requests, pyxbmct, tubed-api }:

buildKodiAddon rec {
  pname = "tubed";
  namespace = "plugin.video.tubed";
  version = "1.0.4";

  src = fetchFromGitHub {
    owner = "anxdpanic";
    repo = "plugin.video.tubed";
    rev = "v${version}";
    sha256 = "0k33vw08hl68gnbrsq6nllz17l6nqq57bkjdkibbn1mmqigvhadn";
  };

  propagatedBuildInputs = [
    inputstream-adaptive
    arrow
    requests
    pyxbmct
    tubed-api
  ];

  # >>> TODO: explain should use https://forum.kodi.tv/showthread.php?tid=274751 instead. or maybe Kodi::GetAddonPath()? https://forum.kodi.tv/showthread.php?tid=336534 <<<
  # This has to be done in postInstall because toKodiAddon
  # (pkgs/applications/video/kodi/build-kodi-addon.nix)'s `installPhase` copies
  # from `$src` rather than `.`
  # TODO: consider changing that and then simplifying this into a `prePatch` section?
  postInstall = ''
    substituteInPlace $out/share/kodi/addons/plugin.video.tubed/resources/lib/src/constants/config.py \
      --replace "special://home/addons/" "special://xbmc/addons/"
  '';


  meta = with lib; {
    homepage = "https://github.com/anxdpanic/plugin.video.tubed";
    description = "Browse your favorite content from YouTube; create, delete, and rename playlists; subscribe or unsubscribe from your favorite channels; and rate your favorite videos.";
    license = licenses.gpl2Only;
    maintainers = teams.kodi.members;
  };
}
