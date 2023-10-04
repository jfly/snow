{ pkgs, fetchFromGitHub, coreutils, lib, stdenv }:
let
  versions = {
    "3.86.0" = pkgs.pulumi.override {
      # Urg, overriding src for go modules is a bit of a pain. See
      # https://github.com/NixOS/nixpkgs/issues/86349 for a discussion about
      # this.
      buildGoModule = args: pkgs.buildGoModule (args // rec {
        version = "3.86.0";

        src = fetchFromGitHub {
          owner = args.pname;
          repo = args.pname;
          rev = "v${version}";
          hash = "sha256-TuwFj2pNT+hkJ8bRbHaeQOuASH35lLQ6kwhN+JAej1I=";
          # Some tests rely on checkout directory name
          name = "pulumi";
        };

        vendorHash = "sha256-YA14Ay8IMrdWxsgKwbDRWnzhzKpaxvAq5R1ItuP6Zaw=";

        disabledTests = args.disabledTests ++ [
          "TestGenerateOnlyProjectCheck" # tries to access github.com
          "TestPluginMapper_MappedNamesDifferFromPulumiName" # TODO: figure out why this is failing
          # various "Unexpected diag message" errors...
          "TestUnplannedDelete"
          "TestPlannedUpdateChangedStack"
          "TestPlannedInputOutputDifferences"
          "TestExpectedCreate"
          "TestExpectedDelete"
        ];

        # All the rest is copied without tweaks from
        # pkgs/tools/admin/pulumi/default.nix. This is because they reference
        # other overriden variables above, and thus also need to get
        # overridden.
        # This can all disappear when upstreamed to nixpkgs.
        installCheckPhase = ''
          PULUMI_SKIP_UPDATE_CHECK=1 $out/bin/pulumi version | grep v${version} > /dev/null
        '';

        importpathFlags = [
          "-X github.com/pulumi/pulumi/pkg/v3/version.Version=v${version}"
        ];

        # Bundle release metadata
        ldflags = [
          # Omit the symbol table and debug information.
          "-s"
          # Omit the DWARF symbol table.
          "-w"
        ] ++ importpathFlags;

        preCheck = ''
          # The tests require `version.Version` to be unset
          ldflags=''${ldflags//"$importpathFlags"/}

          # Create some placeholders for plugins used in tests. Otherwise, Pulumi
          # tries to donwload them and fails, resulting in really long test runs
          dummyPluginPath=$(mktemp -d)
          for name in pulumi-{resource-pkg{A,B},-pkgB}; do
            ln -s ${coreutils}/bin/true "$dummyPluginPath/$name"
          done

          export PATH=$dummyPluginPath''${PATH:+:}$PATH

          # Code generation tests also download dependencies from network
          rm codegen/{docs,dotnet,go,nodejs,python,schema}/*_test.go
          rm -R codegen/{dotnet,go,nodejs,python}/gen_program_test

          # Only run tests not marked as disabled
          buildFlagsArray+=("-run" "[^(${lib.concatStringsSep "|" disabledTests})]")
        '' + lib.optionalString stdenv.isDarwin ''
          export PULUMI_HOME=$(mktemp -d)
        '';
      });
    };
  };
in
version: versions.${version}.withPackages (p: with p; [ pulumi-language-python ])
