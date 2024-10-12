function hack
    cd (mktemp -d)

    echo 'export HACK_DIR=$PWD' > .envrc

    direnv allow
end
