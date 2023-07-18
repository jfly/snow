{ lib, ... }:

let
  mixHash = el: (
    if builtins.isList el then
      builtins.hashString "sha512" (toString (map mixHash el))
    else
      if builtins.isPath el then (builtins.hashFile "sha512" el) else (builtins.hashString "sha512" el)
  );
  short = str: builtins.substring 0 32 str;
  hashForSecret = hostConfig: secret: short (mixHash [ hostConfig.age.rooter.hostPubkey secret.rooterEncrypted ]);
in
rec {
  generatedSecretFilename = hostConfig: secret: "${hashForSecret hostConfig secret}-${hostConfig.networking.hostName}-${secret.name}.age";
  generatedSecretStorePath = hostConfig: secret:
    let
      # Note: it's really important to convert generatedForHostDir from a path to a
      # string all by itself so just it gets copied to the store. If you
      # concatenate first, then you end up with a completely different /nix/store
      # path that:
      #   a) includes more stuff than we need/want.
      #   b) won't actually get included in the resulting closure.
      # I wonder if there's a less weird way of doing this...
      generatedForHostStorePath = lib.throwIfNot (lib.pathExists hostConfig.age.rooter.generatedForHostDir) "${toString hostConfig.age.rooter.generatedForHostDir} does not exist. ${fixitCmd}" "${hostConfig.age.rooter.generatedForHostDir}";
      f = "${generatedForHostStorePath}/${generatedSecretFilename hostConfig secret}";
      fixitCmd = "Run `nix run .#agenix-rooter-generate` to encrypt files for hosts.";
    in
    lib.throwIfNot (lib.pathExists f) "${f} does not exist. ${fixitCmd}" f;

  relativePath = { from, to }:
    let
      fromStr = toString from;
      toStr = toString to;
    in
    # The simplest case is when `to` is a descendent of `from`. Example:
      #   from = /root
      #   to = /root/bar/baz
      # The relative path from `from` to `to` is `bar/baz`, which is just
      # removing the common prefix plus a slash.
    lib.throwIfNot
      (lib.hasPrefix fromStr toStr)
      "'from' must be an ancestor of 'to'. Feel free to add support for more relative relationships if you need it."
      (lib.removePrefix (fromStr + "/") toStr);
}
