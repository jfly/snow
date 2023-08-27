{ python3, fetchFromGitHub, fetchPypi, ffmpeg, bash, lib }:

let
  iso639-lang = python3.pkgs.buildPythonPackage rec {
    pname = "iso639";
    version = "2.1.0";

    src = fetchFromGitHub {
      owner = "LBeaudoux";
      repo = "iso639";
      rev = "v${version}";
      hash = "sha256-d7oLVj/rlyGsdHp36r4ueE6CIvgWdHmAFdPXrs5awbk=";
    };

    propagatedBuildInputs = with python3.pkgs; [
      mutagen
      tqdm
      eyeD3
      setuptools # needs pkg_resources at runtime
    ];
  };

  ebooklib = python3.pkgs.buildPythonPackage rec {
    pname = "EbookLib";
    version = "0.18";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-OFYmQ6e8lNm/VumTC0kn5Ok7XR0JF/aXpkVNtaHBpTM=";
    };

    propagatedBuildInputs = with python3.pkgs; [
      lxml
      six
    ];
  };
in

python3.pkgs.buildPythonApplication rec {
  pname = "odmpy";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "ping";
    repo = "odmpy";
    rev = version;
    hash = "sha256-h0vt4A4c+oV0JBgnBAX6I52Fr+B+rGEjlXTiwKAG+Qo=";
  };

  propagatedBuildInputs = with python3.pkgs; [
    requests
    beautifulsoup4
    lxml
    termcolor
  ] ++ [
    iso639-lang
  ];

  nativeBuildInputs = [
    ffmpeg
  ];

  nativeCheckInputs = with python3.pkgs; [
    pytestCheckHook
    responses
    ebooklib
    coverage
  ];

  makeWrapperArgs = [ "--prefix PATH : ${lib.makeBinPath [ ffmpeg ]}" ];

  patches = [
    # These tests (possibly unintentionally) access the network.
    ./delete_impure_tests.patch
  ];

  preCheck = ''
    # The unittests expect to have a writeable HOME.
    export HOME=$(mktemp -d)
  '';

  checkPhase = ''
    runHook preCheck

    # Strangely, this script does not have a #! nor is executable:
    # https://github.com/ping/odmpy/blob/0.8.0/.github/workflows/lint-test.yml#L85
    ${bash}/bin/bash ./run_tests.sh

    runHook postCheck
  '';
}
