{
  lib,
  runCommand,
  makeWrapper,
  lndir,
  hello,
}:

hello.overrideAttrs {
  # Convenience for calling `makeWrapper` on a given package without losing
  # metadata. Correctly handles multiple output derivations.
  # Is there a simpler way to do this? Does this already exist somewhere? See
  # <https://discourse.nixos.org/t/how-to-wrap-a-package-without-losing-metadata/70695>.
  passthru.wrapPackage =
    pkg: postBuild:
    runCommand "${pkg.name}-wrapped"
      {
        inherit (pkg) version outputs meta;
        nativeBuildInputs = [ makeWrapper ];
      }
      (
        lib.concatStringsSep "\n" (
          map (
            output:
            if output == "out" then
              "mkdir $out && ${lib.getExe lndir} -silent ${pkg.out} $out"
            else
              "ln -s ${pkg.${output}} \$${output}"
          ) (pkg.outputs or [ "out" ])
          ++ [ postBuild ]
        )
      );
}
