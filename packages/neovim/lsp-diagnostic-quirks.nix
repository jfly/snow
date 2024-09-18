# TODO: consider upstreaming to nixvim
{
  lib,
  config,
  pkgs,
  ...
}:

let
  inherit (lib.options) mkOption;

  cfg = config.plugins.lsp.diagnostic-quirks;

  lsp-diagnostics-quirks = pkgs.vimUtils.buildVimPlugin {
    pname = "lsp-diagnostic-quirks.nvim";
    version = "1.0.0";
    src = pkgs.fetchFromGitHub {
      owner = "jfly";
      repo = "lsp-diagnostic-quirks.nvim";
      rev = "f3883cb5c5c39033b4b127c11811ddec6f06858d";
      sha256 = "sha256-bg3uUtdrBd/fGqW/fXviXj04lSacQBZSqaoa89dpOk0=";
    };
  };
in
{
  options = {
    plugins.lsp.diagnostic-quirks.enable = mkOption {
      description = "Enable workarounds for LSP diagnostic quirks";
      type = lib.types.bool;
      default = false;
    };
  };
  config = lib.mkIf cfg.enable {
    extraPlugins = [ lsp-diagnostics-quirks ];
    extraConfigLua = ''require("lsp-diagnostic-quirks").setup()'';
  };
}
