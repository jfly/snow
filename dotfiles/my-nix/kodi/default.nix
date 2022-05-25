{ pkgs }:

let
    media = pkgs.callPackage ./media {};
    my_kodi_with_packages = pkgs.kodi.withPackages (p: [p.a4ksubtitles media]);

    # This is unfortunate: it just doesn't seem to be possible to set some kodi
    # settings without creating files in the ~/.kodi/userdata/addon_data
    # directory. So, we wrap kodi to give us an opportunity to do that.
    genKodiAddonData = pkgs.callPackage ./gen-kodi-addon-data {};
    my_kodi = pkgs.symlinkJoin {
        name = "kodi";
        paths = [ my_kodi_with_packages ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
            wrapProgram $out/bin/kodi \
                --run "${genKodiAddonData}/gen-kodi-addon-data.sh"
        '';
    };
in

my_kodi
