{
  lib,
  fetchFromGitHub,
  python3,
  beets,
  writeTextFile,
}:

let
  pyproject = writeTextFile {
    name = "pyproject.toml";
    text = ''
      [build-system]
      requires = ["hatchling"]
      build-backend = "hatchling.build"

      [project]
      name = "beetsplug"
      version = "0.0.1"
      description = "Artist Images for Beets"
    '';
  };
in
python3.pkgs.buildPythonApplication {
  pname = "beets-fetchartist";
  version = "unstable-2020-07-03";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "dkanada";
    repo = "beets-fetchartist";
    rev = "6ab1920d2ae217bf1c814cdeab220e6d09251aac";
    hash = "sha256-jPm4S02VOYuUgA3wSHX/gdhWIZXZ1k+yLnbui5J/VuU=";
  };

  nativeBuildInputs =
    with python3.pkgs;
    [
      hatchling
    ]
    ++ [ beets ];

  propagatedBuildInputs = with python3.pkgs; [
    beautifulsoup4
    pylast
    requests
  ];

  postUnpack = ''
    cp ${pyproject} source/pyproject.toml
  '';

  doCheck = false;

  meta = with lib; {
    description = "Artist Images for Beets";
    homepage = "https://github.com/dkanada/beets-fetchartist";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "beets-fetchartist";
    platforms = platforms.all;
  };
}
