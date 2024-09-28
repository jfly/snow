function __fish_prompt_format_duration
    set -l milliseconds $argv[1]
    set -l seconds (math "floor($milliseconds / 1000)")

    set -l hours (math "floor($seconds / 3600)")
    set -l seconds (math $seconds % 3600)

    set -l minutes (math "floor($seconds / 60)")
    set -l seconds (math $seconds % 60)

    set -l result ""
    if test $hours -gt 0
        set result {$result}{$hours}h
    end
    if test $minutes -gt 0 || test -n "$result"
        set result {$result}{$minutes}m
    end

    set result {$result}{$seconds}s

    echo $result
end

function fish_prompt --description 'Write out the prompt'
    set -l last_pipestatus $pipestatus
    set -lx __fish_last_status $status # Export for __fish_print_pipestatus.
    set -l normal (set_color normal)
    set -q fish_color_status
    or set -g fish_color_status red

    # Color the prompt differently when we're root
    set -l color_cwd $fish_color_cwd
    set -l suffix_piece '❯'
    if functions -q fish_is_root_user; and fish_is_root_user
        if set -q fish_color_cwd_root
            set color_cwd $fish_color_cwd_root
        end
        set suffix_piece '#'
    end

    set -l suffix ""
    for i in (seq $SHLVL)
        set suffix "$suffix$suffix_piece"
    end

    # Write pipestatus
    # If the status was carried over (if no command is issued or if `set` leaves the status untouched), don't bold it.
    set -l bold_flag --bold
    set -q __fish_prompt_status_generation; or set -g __fish_prompt_status_generation $status_generation
    if test $__fish_prompt_status_generation = $status_generation
        set bold_flag
    end
    set __fish_prompt_status_generation $status_generation
    set -l status_color (set_color $fish_color_status)
    set -l statusb_color (set_color $bold_flag $fish_color_status)
    set -l prompt_status (__fish_print_pipestatus "[" "]" "|" "$status_color" "$statusb_color" $last_pipestatus)

    if test -z $prompt_status
        set statusb_color $normal
    end

    set -l login
    if set -q SSH_TTY
        set login " $(prompt_login) "
    end

    set -l job_info ""
    for i in (seq (count (jobs)))
        set job_info "$job_info"
    end

    if test -n $job_info
        set job_info " $(set_color red)$job_info$normal"
    end

    set -l cwd " $(set_color $color_cwd)$(prompt_pwd --dir-length=0)$normal"

    set -l date " $(set_color cyan)$(date +%H:%M:%S)$normal"

    if test $CMD_DURATION -gt 2500
        set duration " "(set_color yellow)(__fish_prompt_format_duration $CMD_DURATION)$normal
    end

    set -l line1 "$statusb_color╭─$normal$login$cwd$date$(fish_vcs_prompt)$job_info$duration"
    set -l line2 "$statusb_color╰─$normal$prompt_status$suffix "

    echo $line1
    echo -n $line2
end

function postexec_test --on-event fish_postexec
    # Print an extra newline before the prompt.
    # This is a workaround for <https://github.com/fish-shell/fish-shell/issues/10751>.
    echo
end
