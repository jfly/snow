{ lib, ... }:

let
  inherit (lib.nixvim) mkRaw;

  conflictMarker = "<" + "<<";
in
{
  autoCmd = [
    {
      desc = "Modify commentstring to include a conflict marker";
      event = "FileType";
      callback = mkRaw ''
        function()
          vim.bo.commentstring = vim.bo.commentstring:gsub("%%s", "${conflictMarker} %%s")
        end
      '';
    }

    # TODO: explore if snippets are a good alternative to this sort of stuff.
    {
      desc = "Debugger shortcuts for Python";
      event = "FileType";
      pattern = "python";
      command = ''
        nnoremap <leader>d odebugger()#${conflictMarker}<Esc>
        nnoremap <leader>D Odebugger()#${conflictMarker}<Esc>
        nnoremap <leader>o o__import__('os').environ['JFLY'] = '1'#${conflictMarker}<Esc>
        nnoremap <leader>l oif __import__('os').environ.get('JFLY'): __import__('pdb').set_trace()#${conflictMarker}<Esc>
      '';
    }
    {
      desc = "Debugger shortcuts for Bash";
      event = "FileType";
      pattern = "sh";
      command = ''
        nnoremap <leader>d oecho -n 'paused...' && read -r #${conflictMarker}<Esc>
        nnoremap <leader>D Oecho -n 'paused...' && read -r #${conflictMarker}<Esc>
      '';
    }
  ];
}
