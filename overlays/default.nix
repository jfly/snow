[
  (
    self: super:
      let fetchFromGitHub = self.fetchFromGitHub;
      in
      rec {
        # Patch python rxv package. We can remove this once
        # https://github.com/wuub/rxv/pull/90 is merged up, released, and nixpkgs
        # has been updated to use it.
        python3 = super.python3.override {
          # Careful, we're using a different self and super here!
          packageOverrides = self: super: {
            rxv = super.rxv.overridePythonAttrs (old: rec {
              version = "0.7.0+PR10-do-not-assume-assertions-are-enabled";
              src = fetchFromGitHub {
                owner = "jfly";
                repo = "rxv";
                rev = "do-not-assume-assertions-are-enabled";
                sha256 = "0da43lm4zzrmr95vv86gffmfrwcz6v6g5sdkm67jjhw3lhihwx6s";
              };
            });
          };
        };
        python3Packages = python3.pkgs;

        # TODO: remove when (if) https://github.com/NixOS/nixpkgs/pull/242371 gets merged up.
        openvpn3 = super.openvpn3.overrideAttrs (oldAttrs: {
          buildInputs = oldAttrs.buildInputs ++ [ super.systemd ];
          configureFlags = oldAttrs.configureFlags ++ [ "DEFAULT_DNS_RESOLVER=--systemd-resolved" ];
        });

        # TODO: remove beets override once https://nixpk.gs/pr-tracker.html?pr=263650
        #       has landed in nixos-unstable
        beets = super.beets.overridePythonAttrs (old: {
          disabledTests = [
            "test_get_single_item_by_path"
          ];
        });

        snow = {
          # Kind of weird to be hardcoding the path here, but I want this to
          # work in a pure build, which means we can't (and shouldn't) look at
          # something like PWD. For example, if we're building a system using
          # github actions, it really doesn't matter where the repo we're
          # building happens to be cloned.
          absoluteRepoPath = repoPath: "/home/jeremy/src/github.com/jfly/snow" + "/" + (super.lib.strings.removePrefix "/" repoPath);
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
            let hashed = builtins.hashString "sha256" (super.lib.strings.removeSuffix "\n" encrypted);
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
  )
]
