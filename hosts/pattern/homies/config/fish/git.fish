abbr --add g git
abbr --add gst 'git status'
abbr --add gc 'git commit'
abbr --add gcm 'git checkout (git my-main)'
abbr --add glol 'git lol'
abbr --add glola 'git lola'
abbr --add gx 'git x'
abbr --add gd 'git diff'
abbr --add gds 'git diff --staged'
abbr --add gapa 'git add --patch'
abbr --add gc! 'git commit --verbose --amend'
abbr --add gco 'git checkout'
abbr --add gp 'git push'
abbr --add gl 'git pull'
abbr --add gb 'git branch'
abbr --add gwip 'git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"'

bind \ec pick_commits
