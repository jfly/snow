# This is a patched version of Harper that includes an experimental version of
# `tower-lsp`. This fixes an issue where `harper-ls` doesn't actually exit when
# asked to.
#  - https://github.com/ebkalderon/tower-lsp/pull/428
#  - https://github.com/elijah-potter/harper/issues/139
{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

let
  src = fetchFromGitHub {
    owner = "jfly";
    repo = "harper";
    rev = "actually-exit";
    hash = "sha256-0tnaCDq8vV3lw3Jgdl+xbG4nks/o6/YMh7rgM+QOxtI=";
  };
in

rustPlatform.buildRustPackage rec {
  pname = "harper";
  version = "0.12.0-unstable-2024-10-25";

  inherit src;

  cargoLock.lockFile = "${src}/Cargo.lock";

  cargoLock.outputHashes = {
    "tower-lsp-0.20.0" = "sha256-/L5wnvI1t8gWlEmhhafpZJUSUDrJVZMg2rMPVc3Y/cs=";
  };

  meta = {
    description = "Grammar Checker for Developers";
    homepage = "https://github.com/elijah-potter/harper";
    changelog = "https://github.com/elijah-potter/harper/releases/tag/v${version}";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ pbsds ];
    mainProgram = "harper-cli";
  };
}
