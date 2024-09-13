{ inputs, flake, ... }:

let
  inherit (inputs.nixpkgs.lib)
    removePrefix
    ;
in
{
  # Kind of weird to be hardcoding the path here, but I want this to
  # work in a pure build, which means we can't (and shouldn't) look at
  # something like PWD. For example, if we're building a system using
  # github actions, it really doesn't matter where the repo we're
  # building happens to be cloned.
  absoluteRepoPath = repoPath: "/home/jeremy/src/github.com/jfly/snow" + "/" + (removePrefix "/" repoPath);
}
