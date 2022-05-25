{ pkgs }:

let
    # TODO: upstream this to nixpkgs?
    vim-dim = (pkgs.vimUtils.buildVimPluginFrom2Nix {
        pname = "vim-dim";
        version = "1.1.0";
        src = pkgs.fetchFromGitHub {
            owner = "jeffkreeftmeijer";
            repo = "vim-dim";
            rev = "b1332575624e5a212ca702a89f1c78acd88beb22";
            sha256 = "lyTZUgqUEEJRrzGo1FD8/t8KBioPrtB3MmGvPeEVI/g=";
        };
        meta.homepage = "https://github.com/jeffkreeftmeijer/vim-dim/";
    }).overrideAttrs (oldAttrs: {
        preInstall = ''
            f=colors/dim.vim

            # Tweak the gutter color so it stands out from the background.
            echo 'highlight! LineNr ctermbg=8' >> $f
            echo 'highlight! link SignColumn LineNr' >> $f

            # Link diffRemoved and diffAdded to saner values
            # (this is basically copied from https://github.com/dracula/vim/issues/46)
            echo 'highlight! link diffRemoved DiffDelete' >> $f
            echo 'highlight! link diffAdded DiffAdd' >> $f
        '';
    });
in

pkgs.neovim.override {
    vimAlias = true;
    viAlias = true;
    configure = {
        packages.myPackages = with pkgs.vimPlugins; {
            start = [
                fzf-vim
                MatchTagAlways
                matchit-zip
                # Tweak tcomment so comments for (nearly) all languages get the
                # conflict marker characters I'm so used to having.
                (tcomment_vim.overrideAttrs (oldAttrs: {
                    preInstall = ''
                        # Some clever regexes to try to replace all the comment
                        # strings in
                        # https://github.com/tomtom/tcomment_vim/blob/master/autoload/tcomment/types/default.vim
                        # This isn't perfect.
                        f=autoload/tcomment/types/default.vim

                        # Match simple lines like:
                        #     call tcomment#type#Define('aap', '# %s')
                        sed -i "s/\(Define('.*', *'\S\+\)\( %s.*\)/\1<<<\2/" $f

                        # Match lines like:
                        #     call tcomment#type#Define('cpp', tcomment#GetLineC('// %s'))
                        sed -i "s/\(tcomment#GetLineC('\S\+\)\( %s\)/\1<<<\2/" $f

                        # Match lines like:
                        #     call tcomment#type#Define('clojure', {'commentstring': '; %s', 'count': 2})
                        sed -i "s/\('commentstring': \+'\S\+\)\( %s\)/\1<<<\2/" $f

                        # Add some missing definitions
                        echo "call tcomment#type#Define('bash', '#<<< %s')" >> $f
                        echo "call tcomment#type#Define('zsh', '#<<< %s')" >> $f
                        echo "call tcomment#type#Define('dockerfile', '#<<< %s')" >> $f

                        # Override the c definition
                        echo "call tcomment#type#Define('c', tcomment#GetLineC('//<<< %s'))" >> $f

                        # Override the Python definition to make black happy
                        echo "call tcomment#type#Define('python', '# <<< %s')" >> $f
                    '';
                }))

                # Syntax highlighting + colors
                vim-dim
                vim-polyglot

                lightline-vim
                lightline-bufferline
                vim-fugitive
                vim-rhubarb
                vim-test
                traces-vim
                vim-rsi # readline shortcuts in useful places
                vim-mergetool
                (pkgs.vimUtils.buildVimPlugin {
                    pname = "honorjs-test-runner";
                    version = "0.0.1";
                    src = ./plugin;
                })

                # Linting/autofixing/LSP, etc
                editorconfig-vim
                ale
                nvim-lspconfig
                cmp-nvim-lsp
                cmp-buffer
                nvim-cmp
                null-ls-nvim
            ];
        };
        customRC = builtins.readFile ./vimrc;
    };
}
