{ pkgs, python3Packages }:

with python3Packages;
buildPythonApplication {
  pname = "snowcrypt";
  version = "2022-11-29";
  pyproject = true;

  # Repo doesn't currently have any tests.
  doCheck = false;

  build-system = [ setuptools ];

  propagatedBuildInputs = [
    pycryptodome
  ];

  nativeBuildInputs = [ ];

  src = pkgs.fetchFromGitHub {
    owner = "snowskeleton";
    repo = "snowcrypt";
    rev = "5bf4f2f6e2d438f498c808d3a8117c24044c33cf";
    hash = "sha256-LkJXW+oFTZpog2Wmun8vtYLPtOnU2HFR7R4ft1/RSsg=";
  };
}
