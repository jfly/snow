{ ... }:
{
  perSystem =
    { self', pkgs, ... }:
    {
      devShells.default = self'.packages.devShell;
      devShells.kanidm = pkgs.mkShell {
        nativeBuildInputs = [
          self'.packages.kanidm
        ];

        env.KANIDM_URL = "https://auth.m";
      };
    };
}
