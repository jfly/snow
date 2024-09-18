{ pkgs, lib, ... }:

let
  inherit (lib) mapAttrsToList;
  inherit (lib.nixvim) mkRaw;

  keys = {
    "<leader>ts" = ":w<CR>:TestSuite<CR>";
    "<leader>tf" = ":w<CR>:TestFile<CR>";
    "<leader>tn" = ":w<CR>:TestNearest<CR>";
    "<leader>tv" = ":w<CR>:TestVisit<CR>";
    "<leader>tl" = ":w<CR>:TestLast<CR>";
    "<leader>tk" = '':w<CR>:call system("shtuff into " . shellescape(getcwd()) . " \x1BOA")<CR>'';
    "<leader>tt" = ":call ToggleTest(expand('%'))<CR>";
  };
in
{
  extraPlugins = with pkgs.vimPlugins; [ vim-test ];

  globals = {
    "test#strategy" = "shtuff";
    "shtuff_receiver" = mkRaw "vim.loop.cwd()";
  };

  keymaps = mapAttrsToList (key: action: { inherit key action; }) keys;

  # I wrote ToggleTest. It works fine, but this is kind of a mess. Maybe it
  # would be cleaner in Lua (or if I actually *knew* Vimscript).
  # TODO: explore alternatives:
  #  - port to Lua?
  #  - https://github.com/rgroli/other.nvim (links to a few other projects)
  #  - https://github.com/Everduin94/nvim-quick-switcher
  #  - https://www.dev-log.me/Jump_between_test_files_and_implementation_in_Vim/
  #  - https://github.com/drewdeponte/alt
  extraConfigVim = ''
    function Mapped(fn, l)
      """" Copied from https://learnvimscriptthehardway.stevelosh.com/chapters/39.html
      let new_list = deepcopy(a:l)
      call map(new_list, string(a:fn) . '(v:val)')
      return new_list
    endfunction
    function Reversed(l)
      """" Copied from https://learnvimscriptthehardway.stevelosh.com/chapters/39.html
      let new_list = deepcopy(a:l)
      call reverse(new_list)
      return new_list
    endfunction

    function GetToggleFile(path)
      """" This is a two way mapping of "normal" suffixes to/from test suffixes.
      """" If the given path has and of these suffixes, we'll search for a file
      """" ending with the opposite type of suffix. This should let you easily
      """" toggle to/from test files.
      let l:mappings = [
        \[[".py"], ["_test.py"]],
        \[[".js", ".jsx", ".ts", ".tsx"], [".test.js", ".test.jsx", ".test.ts", ".test.tsx"]],
      \]
      let l:reverse_mappings = Mapped(function("Reversed"), l:mappings)
      let l:unknown_suffix = v:true
      for [l:suffixes, l:other_suffixes] in l:mappings + l:reverse_mappings
        for l:suffix in l:suffixes
          let l:basename = a:path[0:-(len(l:suffix)+1)]
          let l:potential_suffix = a:path[-len(l:suffix):-1]

          """" Does the end of the path match this suffix we're looking at?
          if l:potential_suffix ==? l:suffix
            let l:unknown_suffix = v:false
            """" It does match! Let's try appending every possible
            """" other_suffix and if the file exists, that's the winner.
            for l:other_suffix in l:other_suffixes
              let l:other_path = l:basename . l:other_suffix
              if filereadable(l:other_path)
                return l:other_path
              endif
            endfor
          endif
        endfor
      endfor

      """" Uh oh, we don't recognize this suffix. Return empty string as an
      """" indicator that we don't know what to do with this path. Does
      """" vimscript support throwing and catching errors...?
      if l:unknown_suffix
        return ""
      endif

      """" This file doesn't exist, but maybe the user wants to write a new
      """" test! Help them out by opening up a new buffer with an appropriate
      """" filename.
      return l:other_path
    endfunction

    function ToggleTest(path)
      let l:other_path = GetToggleFile(a:path)
      if len(l:other_path) == 0
        echo "I'm not sure how to toggle " . a:path
        return
      endif
      :execute 'edit' l:other_path
    endfunction
  '';
}
