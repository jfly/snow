{ nil }:

# This is a "strict" version of `nil` that treats warnings as errors.
# I've requested an option for this upstream in
# https://github.com/oxalica/nil/issues/151.
nil.overrideAttrs {
  patches = [
    ./werr.patch
  ];
}
