{ pkgs, mach-nix, colmena }:

let
  unwrap = app: pkgs.symlinkJoin {
    name = app.name;
    paths = [ app ];
    buildInputs = [ ];
    postBuild = ''
      for full_path in ${app}/bin/.*-wrapped; do
        f=$(basename $full_path)
        f=''${f#.}  # remove leading dot
        f=''${f%-wrapped}  # remove trailing -wrapped

        rm $out/bin/$f
        cp ${app}/bin/.$f-wrapped $out/bin/$f
        chmod +x $out/bin/$f
      done
    '';
  };
in

pkgs.mkShell {
  nativeBuildInputs = [
    colmena
    pkgs.age
    pkgs.nixpkgs-fmt
    pkgs.just

    # For building portable usb installations.
    pkgs.parted
    pkgs.cloud-utils

    # k8s stuff
    pkgs.kubectl
    # pulumi-bin wraps pulumi with a shell script that sets LD_LIBRARY_PATH,
    # which causes issues when pulumi tries to invoke subprocesses.
    # For example:
    #  $ LD_LIBRARY_PATH=/nix/store/bym6162f9mf4qqsr7k9d73526ar176x4-gcc-11.3.0-lib/lib python --version
    #  /nix/store/x24kxyqwqg2ln8kh9ky342kdcmhbng3h-python3-3.9.9/bin/python: /nix/store/jcb7fny2k03pfbdqk1hcnh12bxgax6vf-glibc-2.33-108/lib/libc.so.6: version `GLIBC_2.34' not found (required by /nix/store/bym6162f9mf4qqsr7k9d73526ar176x4-gcc-11.3.0-lib/lib/libgcc_s.so.1)
    #
    # This environment variable was added a while ago in
    # https://github.com/NixOS/nixpkgs/pull/81879, but things seem to work now
    # without it. :shrug:
    # TODO: file an issue upstream with nixpkgs
    (unwrap pkgs.pulumi-bin)
    pkgs.crd2pulumi
    (
      mach-nix.mkPython {
        # contents of a requirements.txt (use builtins.readFile ./requirements.txt alternatively)
        requirements = ''
          black

          ### Various pulumi requirements
          remote-pdb  # useful for debugging. see https://github.com/pulumi/pulumi/issues/1372 for details
          pip  # used by `pulumi about`
          rich
          pulumi>=3.0.0,<4.0.0
          pulumi-kubernetes>=3.0.0,<4.0.0
          pulumi-cloudflare>=3.0.0,<4.0.0
          setuptools  # provides pkg_resources which is needed by pulumi-kubernetes: https://github.com/pulumi/pulumi-kubernetes/blob/ce9ab9137af0aa53ceddb18104fce194cb1a0228/sdk/python/pulumi_kubernetes/_utilities.py#L10, despite not being mentioned in its setup.py? =(
        '';
        packagesExtra = [
          (mach-nix.buildPythonPackage ./k8s-pulumi/crds/python)
        ];
      }
    )
  ];

  # Set up credentials to talk to minio (a self-hosted file server that
  # implements the s3 api).
  AWS_ACCESS_KEY_ID = pkgs.deage.optionalString "AWS_ACCESS_KEY_ID" ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSByc0RjL1VESElmbnVDQ0Jk
    VVBITXgrSlk0MTFuTlVQTGtqeXUyMytIblVjClZIb1ZDbHlBZjJDcnQyQW9GZzNW
    NENERWJUOU4wZTJ1eFFkNE14WmFBcWcKLS0tIHYxNFBCUFlnc3BaY1d2eldMR2hz
    TmZicEdlVUVpYm9odzZSUkN0ZGJnRlkKAPIKfC6SSsQNQLqWWqVN+MucUVN1l1D6
    g/S7HsJm5j46iTYN
    -----END AGE ENCRYPTED FILE-----
  '';
  AWS_SECRET_ACCESS_KEY = pkgs.deage.optionalString "AWS_SECRET_ACCESS_KEY" ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSB2SGtaRlN5Q0IrQXFnQXR2
    MytRSXFkcGd6MXh3M05xdldEY3Z0WTNNZGdjCjltUWc2S3RMWWRId0g0eUVUUHhz
    Umk2empWSXF3dTVMcmgyeE5pbVc2dWsKLS0tIFpwNFFnN1FHbFBJVHpDckk1S1d0
    Sm00MWpvbVJlWk4vVkIrb09MQmxhQkkKeeZwFEYdQFVyok+F/FEpGjK2I6hXOTxy
    yeQL3c9LBDac5ZjwmxWse7JyLStg0Sk3XrG0rQ==
    -----END AGE ENCRYPTED FILE-----
  '';
  # This region doesn't mean anything to minio, but some AWS sdks expect you
  # to have a region set.
  AWS_REGION = "us-west-2";

  PULUMI_CONFIG_PASSPHRASE = pkgs.deage.optionalString "PULUMI_CONFIG_PASSPHRASE" ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSB6RU0wSVR1cWJMUFRkSUxG
    enRmWnpZL2V5c2JFb3FaOTFqTGRlbVVYMUE4CnQzdmlpa2U3QjJxQ2RtQUpRMVBh
    WWk0YjZPYlNMYW85b1VNOHdlMVAzVEUKLS0tIGJCaThVR3RvT0pVRnNCR21NbmpP
    RVJnMjg3b3VGL2NxWG1ZN2syaUdBNGMKS7ChE4gYpW90dInSGzPYBZOZsLMi0l+o
    U/ZyGUi0NXR+3mzKtN9j/mgPmrGzmfvhkGFVWA==
    -----END AGE ENCRYPTED FILE-----
  '';

  CLOUDFLARE_API_TOKEN = pkgs.deage.optionalString "CLOUDFLARE_API_TOKEN" ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSAzZ3N2WHlBclZHWFI4L1NR
    K2MzQzJMbnVtdEFhei9VNEpTSWtwSDFjVFg4Cmt2WWd2b0tKaVNHUmFwWHJ0SzRE
    bENHS2dra3pGZUMvS045OXhvTzJmbWcKLS0tIDdLNlF2UjdzZERLVS93ck02RHB0
    dXozSTh5d2s2UStWUjg0cHJlUWRxYVEKX/TReXYpi1At4fYpLvCmEgnE2GUgiqBF
    mXity+YrzMYSevmN58otx7C8qiHtMbIhrX+fpgPseku5BvHUad2XloHk5m1d/26K
    -----END AGE ENCRYPTED FILE-----
  '';

  shellHook = ''
    export KUBECONFIG=$PWD/k8s/kube/config.secret
  '';
}
