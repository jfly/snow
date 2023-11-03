{
  description = "Build some stuff for my kobo";

  outputs = { self, nixpkgs }@args:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      packages = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in
        rec {
          fonts = pkgs.callPackage ./fonts.nix { };
          install = pkgs.writeShellScript "kobo-install.sh" ''
            KOBO_SANITY_CHECK_DIR=/mnt/kobo/.kobo
            if [ ! -d "$KOBO_SANITY_CHECK_DIR" ]; then
              echo "Could not find $KOBO_SANITY_CHECK_DIR. Aborting." >/dev/stderr
              exit 1
            fi
            ${pkgs.rsync}/bin/rsync --archive --copy-links --delete ${fonts}/ /mnt/kobo/fonts
            echo "Successfully installed fonts on your kobo!"
          '';
        }
      );
      apps = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in
        {
          install = {
            type = "app";
            program = builtins.toString self.packages.${system}.install;
          };
        }
      );
    };
}
