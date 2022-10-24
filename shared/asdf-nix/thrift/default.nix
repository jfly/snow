{ pkgs }:

let
  commitByVersion = {
    "0.12.1" = "08be79f5b2257383fb8d9c6a86fcda945d6b9548";
  };
in
(version:
let commit = commitByVersion.${version};
in
pkgs.stdenv.mkDerivation {
  name = "thrift";
  nativeBuildInputs = with pkgs; [
    yacc
    flex
    libtool
    automake
    autoconf
    pkgconfig
    boost
    openssl
  ];
  bootstrap = "./bootstrap.sh";
  preConfigurePhases = "bootstrap";
  src = builtins.fetchGit {
    url = "git@github.com:joinhonor/apache-thrift.git";
    ref = "honor-${version}";
    rev = commit;
  };
  # The thrift build runs `git log` to to figure out the git commit hash that's
  # being built to include in the output of `--version`. Nix strips out the
  # .git directory when using a git source. There are ways to preserve that
  # directory, but it sounds like they cause trouble with determinism, and the
  # advice is to submit a patch upstream to provide some git-less mechanism for
  # threading this information around. See this thread for a discussion about this:
  # https://discourse.nixos.org/t/keep-git-folder-in-when-fetching-a-git-repo/8590/3
  GIT_COMMIT = commit;
  patches = [
    # TODO: upstream this. It gives us a git-less mechanism to inject the
    # commit hash into `thrift --version`. See comment above for why this is
    # preferred.
    ./no-git-thrift-version.patch
  ];
})
