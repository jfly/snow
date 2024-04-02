{ buildPythonPackage, fetchPypi, requests, setuptools }:

# TODO: consider upstreaming this to nixpkgs?
buildPythonPackage rec {
  pname = "pyedid";
  version = "1.0.3";
  pyproject = true;

  propagatedBuildInputs = [
    setuptools
    requests
  ];

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-5huO97aAbsU26pcb9lDjRw9qnNrplNb1DS2Xw/jxuPQ=";
  };
}
