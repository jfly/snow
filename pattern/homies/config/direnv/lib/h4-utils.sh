# shellcheck shell=bash

### Do not edit. This file was autogenerated by the Honor dev setup scripts: https://github.com/joinhonor/dev-setup-scripts.
use_asdf() {
    source_env "$(asdf direnv envrc "$@")"
}

# This is a version of direnv's `layout_python` that implements option #1
# described in https://github.com/direnv/direnv/issues/1239. See
# https://joinhonor.atlassian.net/browse/FOUND-4939 for more information.

__ensure_symlink() {
    local target=$1
    local name=$2

    if [ -L "$name" ]; then
        local current_target
        current_target=$(readlink "$name")
        if [ "$current_target" = "$target" ]; then
            # The existing symlink is up to date, great! Nothing to do.
            return
        else
            # The existing symlink is out of date. Delete it, and fall through
            # to the code to create a symlink below.
            rm "$name"
        fi
    elif [ -d "$name" ]; then
        # This is probably just an old venv created before this workaround for
        # https://github.com/direnv/direnv/issues/1239. Just delete it.
        rm -r "$name"
    elif [ -e "$name" ]; then
        echo "I'm not sure what's going on with $name" >/dev/stderr
        echo "Out of an abundance of caution, I'm going to abort." >/dev/stderr
        echo "To remove it and try again, try something like 'rm -r $name && direnv reload'" >/dev/stderr
        exit 1
    fi

    ln -s "$target" "$name"
}

layout_python() {
    local old_env
    local python=${1:-python}
    [[ $# -gt 0 ]] && shift
    old_env=$(direnv_layout_dir)/virtualenv
    unset PYTHONHOME
    if [[ -d $old_env && $python == python ]]; then
        VIRTUAL_ENV=$old_env
    else
        local python_full_version ve
        # shellcheck disable=SC2046
        read -r python_full_version python_major_version ve <<<$($python -c "import pkgutil as u, platform as p;ve='venv' if u.find_loader('venv') else ('virtualenv' if u.find_loader('virtualenv') else '');full=p.python_version();major='.'.join(p.python_version_tuple()[:2]);print(full+' '+major+' '+ve)")
        if [[ -z $python_full_version ]]; then
            log_error "Could not find python's version"
            return 1
        fi

        if [[ -n ${VIRTUAL_ENV:-} ]]; then
            local REPLY
            realpath.absolute "$VIRTUAL_ENV"
            VIRTUAL_ENV=$REPLY
            VIRTUAL_ENV_ALT_NAME=""
        else
            VIRTUAL_ENV=$(direnv_layout_dir)/python-$python_full_version
            VIRTUAL_ENV_ALT_NAME=$(direnv_layout_dir)/python-$python_major_version
        fi
        case $ve in
            "venv")
                if [[ ! -d $VIRTUAL_ENV ]]; then
                    $python -m venv "$@" "$VIRTUAL_ENV"
                fi
                ;;
            "virtualenv")
                if [[ ! -d $VIRTUAL_ENV ]]; then
                    $python -m virtualenv "$@" "$VIRTUAL_ENV"
                fi
                ;;
            *)
                log_error "Error: neither venv nor virtualenv are available."
                return 1
                ;;
        esac

        if [ -n "$VIRTUAL_ENV_ALT_NAME" ]; then
            __ensure_symlink "$VIRTUAL_ENV" "$VIRTUAL_ENV_ALT_NAME"
        fi
    fi

    # Create a .venv symlink at the root. This helps some editors (specifically
    # PyCharm) automatically discover the virtual environment.
    __ensure_symlink "$VIRTUAL_ENV" "$PWD/.venv"

    export VIRTUAL_ENV
    PATH_add "$VIRTUAL_ENV/bin"
}

# Wrap the given executable file and add it to the PATH.
# Usage: wrap_program EXECUTABLE ARGS
#
# See `make_wrapper` for supported ARGS.
wrap_program() {
    local wrap_me=$1
    shift # skip past first argument

    # Its possible that multiple processes may run when setting up a direnv. To address this race condition, we
    # initially write our wrapper script to a temporary file, then move it to the final location.
    local basename
    basename=$(basename "$wrap_me")
    temp_wrapper=$(mktemp)
    wrapper=$(direnv_layout_dir)/wrappers/$basename-wrapper/$basename
    wrapper_dir=$(dirname "$wrapper")

    make_wrapper "$wrap_me" "$temp_wrapper" "$@"

    mkdir -p "$wrapper_dir"
    mv "$temp_wrapper" "$wrapper"

    PATH_add "$wrapper_dir"
}

# Wrap the given executable file.
# Usage: make_wrapper EXECUTABLE OUT_PATH ARGS
#
# This only supports a small subset of the features in [the original]. Feel free to duplicate functionality over as needed.
#
# [the original]: https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
#
# ARGS:
# --run       COMMAND : run COMMAND before EXECUTABLE
make_wrapper() {
    local wrap_me=$1
    local wrapper=$2

    if ! [[ -f $wrap_me && -x $wrap_me ]]; then
        log_error "wrap_program: Cannot wrap '$wrap_me' as it is not an executable file"
        exit 1
    fi

    echo "#!/usr/bin/env bash" >"$wrapper"
    echo "set -e" >>"$wrapper"

    params=("$@")
    for ((n = 2; n < ${#params[*]}; n += 1)); do
        p="${params[$n]}"

        if [[ $p == "--run" ]]; then
            command="${params[$((n + 1))]}"
            n=$((n + 1))
            echo "$command" >>"$wrapper"
        else
            die "make_wrapper doesn't understand the arg $p"
        fi
    done

    echo exec "'$wrap_me'" '"$@"' >>"$wrapper"
    chmod +x "$wrapper"
}

wrap_with_codeartifact_login() {
    local command=$1
    local tool_specific_args=$2

    # shellcheck disable=SC2016 # we are intentionally using single quotes so we can gerate bash code (:scream:)
    wrap_program "$(which "$command")" --run '
# Wrapper for '"$command"' that first authenticates with AWS CodeArtifact.
# See https://joinhonor.atlassian.net/browse/FOUND-4904 for details.

if [ -n "${H4_AUTHENTICATING_WITH_CODEARTIFACT:-}" ]; then
    # Calling `aws codeartifact login` can result in a call to something like
    # `npm config set`, but we may be wrapping npm itself, which would result
    # in an infinite recursion. So, we first set the
    # `H4_AUTHENTICATING_WITH_CODEARTIFACT` environment variable as an
    # indicator of if we are currently authenticating with AWS. If we are, just
    # invoke the original unwrapped tool.
    echo "Skipping AWS CodeArtifact authentication as we appear to already be authenticating." >/dev/stderr
else
    echo "Refreshing AWS CodeArtifact authentication." >/dev/stderr
    export H4_AUTHENTICATING_WITH_CODEARTIFACT=1

    # Note: we direct *all* output from this command to stderr. We are very
    # careful to not print anything to stdout in this wrapper because we do not
    # want to break anyone doing any clever parsing of output from these tools
    # (such as parsing `npm --version`).
    #
	# Note: ecr-local is (now) poorly named as we use it for both pulling docker
	# images *and* pulling packages: https://joinhonor.atlassian.net/browse/FOUND-4826
    (
        # We cd into the home directory as a workaround for
        # https://github.com/aws/aws-cli/issues/8555. This is safe: we do not
        # want this to be a project specific thing, we just want to update the
        # `~/.npmrc` file.
        cd ~
        AWS_PROFILE=ecr-local aws codeartifact login --domain honorcare --repository honorcare-prod --domain-owner 900965112463 --region us-west-2 '"$tool_specific_args"' 1>&2
    )
    unset H4_AUTHENTICATING_WITH_CODEARTIFACT
fi
'
}

h4_authenticate_python() {
    local command=$1
    # shellcheck disable=SC2016 # we are intentionally using single quotes so we can generate bash code (:scream:)
    wrap_program "$(which "$command")" --run '
# Wrapper for '"$command"' that first authenticates with AWS CodeArtifact.
# See https://joinhonor.atlassian.net/browse/FOUND-4904 for details.
# Delegates getting an AWS CodeArtifact authorization token to the Honor Cli. Use that token to authenticate
# poetry and pip with Honors CodeArtifact honorcare-prod repository
codeartifact_auth_token=$(honor login codeartifact token)

# Configure AWS CodeArtifact authentication for pip
export PIP_INDEX_URL="https://aws:${codeartifact_auth_token}@honorcare-900965112463.d.codeartifact.us-west-2.amazonaws.com/pypi/honorcare-prod/simple/"

# Configure Poetry to authenticate to CodeArtifact honorcare-prod repository
# https://python-poetry.org/docs/repositories/
export POETRY_HTTP_BASIC_HONORCARE_PROD_USERNAME=aws
export POETRY_HTTP_BASIC_HONORCARE_PROD_PASSWORD=$codeartifact_auth_token
'
}
