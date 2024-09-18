# This overrides Neovim's builtin `<C-p>/<C-n>` keyword completion to use
# nvim-cmp/cmp-buffer instead.
# I'm partial to this because it gives us us consistent behavior between both
# completion mechanisms (including nvim-cmp's fancy ghost text).
#
# I'm not sure if this is the cleanest way to do
# this. I asked about this in https://github.com/hrsh7th/cmp-buffer/issues/78,
# hopefully someone provides a better approach.

{ lib, ... }:

let
  inherit (lib.nixvim) mkRaw;
in
{
  keymaps = [
    {
      key = "<C-n>";
      action = mkRaw ''require("cmp").complete'';
      mode = "i";
    }
    {
      key = "<C-p>";
      action = mkRaw ''require("cmp").complete'';
      mode = "i";
    }
  ];

  plugins.cmp.settings.sources = [
    {
      name = "manually-invoked-buffer"; # provided by ./override-keyword-completion-with-cmp-buffer.nix
      group_index = 99;
    }
  ];

  plugins.cmp-buffer.enable = true;
  extraConfigLuaPost = ''
    do
      local cmp = require("cmp")
      local types = require("cmp.types")

      local function wrap_source(wrapme)
        local wrapped = {}

        setmetatable(wrapped, {
            __index = function(_, key)
              local value = wrapme[key]
              if key == "complete" then
                return function(_, params, callback)
                  local manual = params.context:get_reason() == types.cmp.ContextReason.Manual

                  if manual then
                    return wrapme:complete(params, callback)
                  else
                    return callback()
                  end
                end
              elseif type(value) == "function" then
                return function(_, ...)
                  return value(wrapme, ...)
                end
              else
                return value
              end
            end
        })

        return wrapped
      end

      cmp.register_source('manually-invoked-buffer', wrap_source(require('cmp_buffer')))
    end
  '';
}
