{ inputs }:

self: super:
let
  inherit (self)
    fetchFromGitHub
    ;
  inherit (self.lib)
    makeScope
    removePrefix
    removeSuffix
    ;
in
rec {
  snow = (self.callPackage ./pkgs { }) // {
    # Kind of weird to be hardcoding the path here, but I want this to
    # work in a pure build, which means we can't (and shouldn't) look at
    # something like PWD. For example, if we're building a system using
    # github actions, it really doesn't matter where the repo we're
    # building happens to be cloned.
    absoluteRepoPath = repoPath: "/home/jeremy/src/github.com/jfly/snow" + "/" + (removePrefix "/" repoPath);

    on-air = inputs.on-air.packages.${self.hostPlatform.system}.default;
    shtuff = inputs.shtuff.packages.${self.hostPlatform.system}.default;
    with-alacritty = inputs.with-alacritty.packages.${self.hostPlatform.system}.default;
  };

  deage = rec {
    absoluteRepoPath = encrypted: snow.absoluteRepoPath (repoPath encrypted);
    storeFile = { name, encrypted }: (
      let absPath = deage.absoluteRepoPath encrypted;
      in
      super.writeTextFile {
        inherit name;
        text = builtins.readFile absPath;
      }
    );
    repoPath = encrypted: (
      let hashed = builtins.hashString "sha256" (removeSuffix "\n" encrypted);
      in "./.sensitive-decrypted-secrets/${hashed}.secret"
    );
    string = encrypted: builtins.readFile (absoluteRepoPath encrypted);
    optionalString = description: encrypted: (
      let
        missingMsg = "Could not find decrypted ${description}. Try running `tools/deage && direnv reload`";
      in
      if builtins.pathExists (absoluteRepoPath encrypted) then builtins.readFile (absoluteRepoPath encrypted) else builtins.trace missingMsg missingMsg
    );
  };
}
