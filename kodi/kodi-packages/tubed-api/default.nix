{ lib, buildKodiAddon, fetchFromGitHub, requests }:

buildKodiAddon rec {
  pname = "tubed";
  namespace = "script.module.tubed.api";
  version = "1.0.10";

  src = fetchFromGitHub {
    owner = "anxdpanic";
    repo = "script.module.tubed.api";
    rev = "v${version}";
    sha256 = "1g4f7x6vknvmkqnl6n9rs5iap14sjwp3za6lx8b9r0bg77afi5wa";
  };

  propagatedBuildInputs = [
    requests
  ];

  meta = with lib; {
    homepage = "https://github.com/anxdpanic/script.module.tubed.api";
    description = "The Tubed API module provides a convenient way to access YouTube's Data API in Kodi 19+";
    license = licenses.gpl2Only;
    maintainers = teams.kodi.members;
  };
}
