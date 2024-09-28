function de
    set --local container $argv[1]
    set --erase argv[1]

    set --local cmd docker exec -it $container env TERM=xterm bash
    if test (count $argv) -gt 0
        set cmd $cmd -c "$argv"
    end

    string escape -- $cmd | string join ' '

    $cmd
end

function dr
    set --local image $argv[1]
    set --erase argv[1]

    set --local cmd docker run -it --entrypoint=bash $image
    if test (count $argv) -gt 0
        set cmd $cmd -c "$argv"
    end

    string escape -- $cmd | string join ' '

    $cmd
end
