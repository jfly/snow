{
  lib,
  buildKodiAddon,
  fetchFromGitHub,
  bottle,
  requests,
  youtube,
}:

buildKodiAddon rec {
  pname = "tubecast";
  namespace = "script.tubecast";
  version = "1.4.8+matrix.1";

  src = fetchFromGitHub {
    owner = "enen92";
    repo = "script.tubecast";
    rev = version;
    sha256 = "194lf7h84fqp1kjrp7skd2g9af6g3dlhjf1vhwgpbpdrsl7fdg7j";
  };

  propagatedBuildInputs = [
    bottle
    requests
    # This plugin optionally depends on tubed or youtube. Both plugins seem to
    # have issues with api keys, pick your poison.
    # tubed
    youtube
  ];

  meta = with lib; {
    homepage = "https://github.com/enen92/script.tubecast";
    description = "An implementation of the Cast V1 protocol in Kodi to act as a player for the Youtube mobile application";
    license = licenses.mit;
    maintainers = teams.kodi.members;
  };
}
