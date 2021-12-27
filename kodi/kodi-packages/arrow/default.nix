{ lib, buildKodiAddon, fetchFromGitHub, addonUpdateScript, dateutil }:
buildKodiAddon rec {
  pname = "arrow";
  namespace = "script.module.arrow";
  version = "1.0.3.1";

  src = fetchFromGitHub {
    owner = "razzeee";
    repo = "script.module.arrow";
    rev = "v${version}";
    sha256 = "0xa16sb2hls59l4gsg1xwb1qbkhcvbykq02l05n5rcm0alg80l3l";
  };

  propagatedBuildInputs = [
    dateutil
    # Note: `typing_extensions` is declared as a dependency:
    # https://github.com/razzeee/script.module.arrow/blob/v1.0.3.1/addon.xml#L9
    # But https://github.com/Razzeee/script.module.typing_extensions says:
    #
    # > Users of other Python versions should continue to install and use
    # > specifically writing code that must be compatible with multiple Python
    # > use the ``typing`` module from PyPi instead of using this one unless
    # > versions or requires experimental types.
    #
    # We're using a modern version of Python, and we're not trying to be
    # compatible with old versions, so I think we can just skip this
    # dependency.
  ];

  meta = with lib; {
    homepage = "https://github.com/Razzeee/script.module.arrow";
    description = "Packed for Kodi from https://github.com/crsmithdev/arrow";
    license = licenses.asl20;
    maintainers = teams.kodi.members;
  };
}
