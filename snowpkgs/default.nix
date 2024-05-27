{ pkgs, }:

let
  entries = builtins.readDir ./.;
  filenames = builtins.attrNames entries;

  maybeNameValuePair = filename:
    if entries.${filename} == "directory"
    then [
      {
        name = filename;
        value = pkgs.callPackage (./. + "/${filename}") { };
      }
    ]
    else [ ];
  nameValuePairs = builtins.concatMap maybeNameValuePair filenames;
in

builtins.listToAttrs nameValuePairs
