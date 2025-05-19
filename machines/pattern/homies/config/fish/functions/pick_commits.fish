function __pick_commits
    set -l commits
    for item in (git lola --color=always | fzf --ansi --no-sort --reverse --multi)
        # Parse a item like this:
        #
        #  * 1625c61 - (HEAD -> main) Drop nix-zshell (2 hours ago) <Jeremy Fleischman>
        #
        set -l commit (string match --regex --groups-only " *\* ([^ ]+)" $item)

        set commits $commits $commit
    end

    echo (string join " " $commits)
end

function pick_commits
    set -l commits (__pick_commits)
    commandline --insert -- $commits
end
