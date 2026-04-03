{
  lib,
  inputs',
  writeShellApplication,
  writeTextFile,
  nushell,
  git,
}:

let
  git-status = writeShellApplication {
    name = "git-status";
    runtimeInputs = [
      git
      inputs'.devshell-init.packages.default
    ];
    text = ''
      # Check for a dirty git tree (untracked, unstaged, or staged changed).
      if [ -n "$(git status --porcelain)" ]; then
          echo "dirty"
      # Check for stashed changes.
      elif [ -n "$(git stash list)" ]; then
          echo "stashed"
      # Check for unpushed branches.
      elif [ -n "$(git log --branches --not --remotes)" ]; then
          echo "unpushed"
      # If there are any untracked files ignored by `.git/info/exclude`, check if we can
      # recreate the devshell (as that's the only way I currently use `.git/info/exclude`).
      elif [ -n "$(git ls-files --ignored --others --exclude-from=.git/info/exclude)" ] && ! devshell-init --check >/dev/null; then
          echo "unrecreatable-devshell"
      else
          echo "synced"
      fi
    '';
  };

  reportSpec = # toml
    writeTextFile {
      name = "src-report.toml";
      text = /* toml */ ''
        [[categories]]
        name = "git"
        command = ["test", "-e", ".git"]

        [[categories.stats]]
        name = "status"
        command = ["${lib.getExe git-status}"]

        [[categories.stats]]
        name = "size (bytes)"
        command = ["${lib.getExe nushell}", "--commands", "du . | first | get physical | into int"]

        [[categories]]
        name = "git-bare"
        command = ["git", "rev-parse", "--is-bare-repository"]
      '';
    };
in
writeShellApplication {
  name = "src-report";
  runtimeInputs = [
    inputs'.treeport.packages.default
  ];
  text = ''
    exec treeport ${reportSpec} --root ~/src
  '';
}
