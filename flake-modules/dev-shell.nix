{ ... }: {
  perSystem = { self', ... }: {
    devShells.default = self'.packages.devShell;
  };
}
