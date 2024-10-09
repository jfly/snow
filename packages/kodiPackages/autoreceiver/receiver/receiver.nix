{ python3Packages, fetchFromGitHub }:

with python3Packages;
buildPythonApplication {
  pname = "receiver";
  version = "1.0";

  propagatedBuildInputs = [
    (
      # Patch python rxv package. We can remove this once
      # https://github.com/wuub/rxv/pull/90 is merged up, released, and nixpkgs
      # has been updated to use it.
      rxv.overridePythonAttrs (old: {
        version = "0.7.0+PR10-do-not-assume-assertions-are-enabled";
        src = fetchFromGitHub {
          owner = "jfly";
          repo = "rxv";
          rev = "do-not-assume-assertions-are-enabled";
          sha256 = "0da43lm4zzrmr95vv86gffmfrwcz6v6g5sdkm67jjhw3lhihwx6s";
        };
      })
    )
  ];

  src = ./.;
}
