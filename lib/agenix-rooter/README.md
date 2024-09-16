# agenix-rooter

An agenix extension that lets you manage secrets encrypted with a single master
key and easily re-encrypt them for each host. Like [agenix-rekey], but you
actually commit the "rekeyed" files instead of doing an impure build to produce
a local derivation that contains them.

TODO: get rid of this! it's no longer necessary now that agenix-rekey supports
"local" storage mode:
https://github.com/oddlama/agenix-rekey/commit/7828b0f57e5d315be0da9892c1b02b7077a15ecc

[agenix-rekey]: https://github.com/oddlama/agenix-rekey
