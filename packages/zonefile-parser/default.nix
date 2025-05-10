{
  buildPythonPackage,
  fetchPypi,
  lib,
  setuptools,
  wheel,
}:

buildPythonPackage rec {
  pname = "zonefile-parser";
  version = "0.1.18";
  pyproject = true;

  src = fetchPypi {
    pname = "zonefile_parser";
    inherit version;
    hash = "sha256-dS4YpQLI7bLkSgJCcxo5HBHruxkru49/KXvZvi8PuHk=";
  };

  build-system = [
    setuptools
    wheel
  ];

  pythonImportsCheck = [
    "zonefile_parser"
  ];

  meta = {
    description = "Library for parsing dns zone files";
    homepage = "https://pypi.org/project/zonefile-parser/";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jfly ];
    mainProgram = "zonefile-parser";
  };
}
