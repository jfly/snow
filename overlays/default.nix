[(
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
        rxv = super.rxv.overridePythonAttrs(old: rec {
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

    deage = rec {
      file = encrypted: (
        let hashed = builtins.hashString "sha256" (super.lib.strings.removeSuffix "\n" encrypted);
        in ../.sensitive-decrypted-secrets + "/${hashed}.secret"
      );
      string = encrypted: builtins.readFile(file encrypted);
    };
  }
)]
