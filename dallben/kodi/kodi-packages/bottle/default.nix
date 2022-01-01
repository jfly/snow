{ lib, buildKodiAddon, fetchzip, addonUpdateScript, certifi, chardet, idna, urllib3 }:
buildKodiAddon rec {
  pname = "bottle";
  namespace = "script.module.bottle";
  version = "0.12.18+matrix.2";

  src = fetchzip {
    url = "https://mirrors.kodi.tv/addons/matrix/${namespace}/${namespace}-${version}.zip";
    sha256 = "16x0kzdhjgim7k2qfk4sp9283i7gba9gnxjf0qvhjq1j3j7k65x8";
  };

  passthru = {
    pythonPath = "lib";
    updateScript = addonUpdateScript {
      attrPath = "kodi.packages.bottle";
    };
  };

  meta = with lib; {
    homepage = "https://bottlepy.org/docs/dev/";
    description = "Bottle is a fast and simple micro-framework for small web applications. It offers request dispatching (Routes) with url parameter support, templates, a built-in HTTP Server and adapters for many third party WSGI/HTTP-server and template engines - all in a single file and with no dependencies other than the Python Standard Library.";
    license = licenses.mit;
    maintainers = teams.kodi.members;
  };
}
