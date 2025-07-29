# TODO: consider upstreaming to nixvim
{
  lib,
  config,
  pkgs,
  ...
}:

let
  inherit (lib.options) mkOption;

  cfg = config.plugins.lsp-diagnostic-quirks;

  lsp-diagnostics-quirks = pkgs.vimUtils.buildVimPlugin {
    pname = "lsp-diagnostic-quirks.nvim";
    version = "1.0.1";
    src = pkgs.fetchFromGitHub {
      owner = "jfly";
      repo = "lsp-diagnostic-quirks.nvim";
      rev = "v${lsp-diagnostics-quirks.version}";
      hash = "sha256-jEnbyo9qIyXKRdUh4fpdcl1akCH2/xCpJiPoMuYUu78=";
    };
  };
in
{
  options = {
    plugins.lsp-diagnostic-quirks.enable = mkOption {
      description = "Enable workarounds for LSP diagnostic quirks";
      type = lib.types.bool;
      default = false;
    };
  };
  config = lib.mkIf cfg.enable {
    extraPlugins = [ lsp-diagnostics-quirks ];
    extraConfigLua = ''require("lsp-diagnostic-quirks").setup()'';

    # extraConfigLuaPre = ''
    #   vim.opt.rtp:prepend("/home/jeremy/src/github.com/jfly/lsp-diagnostic-quirks.nvim")
    # '';
  };
}
