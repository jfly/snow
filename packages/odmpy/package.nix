{
  python3,
  fetchFromGitHub,
  ffmpeg,
  bash,
  lib,
}:

let
  iso639-lang = python3.pkgs.buildPythonPackage rec {
    pname = "iso639";
    version = "2.5.1";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "LBeaudoux";
      repo = "iso639";
      rev = "v${version}";
      hash = "sha256-NMArGcr2FHmB6o9cySceLw8SVTdJtbG7SdrT2qzkcqI=";
    };

    propagatedBuildInputs = with python3.pkgs; [
      mutagen
      tqdm
      eyeD3
      setuptools # needs pkg_resources at runtime
    ];
  };
in

python3.pkgs.buildPythonApplication rec {
  pname = "odmpy";
  version = "0.8.1";

  src = fetchFromGitHub {
    owner = "ping";
    repo = "odmpy";
    rev = version;
    hash = "sha256-RWaB/W8ilAKRr0ZSISisCG8Mdgw5LXRCLOl5o1RsmbA=";
  };

  propagatedBuildInputs =
    with python3.pkgs;
    [
      requests
      beautifulsoup4
      lxml
      termcolor
      ebooklib
    ]
    ++ [
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
