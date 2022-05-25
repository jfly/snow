#!/usr/bin/env bash

# Clone all repositories from an organization.

set -e

if [ $# -ne 2 ]; then
    echo "Usage:"
    echo "    $0 [gh-organization] [directory]"
    echo ""
    echo "If the given directory does not exist, it will be created."
    echo "If the given directory does exist, then missing repositories will be added, and you will get warnings about unexpected repositories."
    echo ""
    echo "For example, to clone all repostories under the 'thewca' GitHub organization into the current directory:"
    echo "    $0 thewca ."
    exit 1
fi

GH_ORG="$1"
DEST_DIR="$2"
mkdir -p "$DEST_DIR"
cd "$DEST_DIR"

# Ideally we wouldn't put a limit here, but the `gh` cli tool seems to require
# one, so here's a hopefully ridiculously high limit.
REPO_LIMIT=10000
expected_repos=$(gh repo list $GH_ORG --no-archived --json sshUrl --jq '.[].sshUrl' --limit "$REPO_LIMIT" | sort)
found_repos=$(grep -Pho "(?<=url = ).*"  */.git/config | sort)

missing_repos=$(comm -23 <(echo "$expected_repos") <(echo "$found_repos"))
unexpected_repos=$(comm -13 <(echo "$expected_repos") <(echo "$found_repos"))

# TODO: This is going to warn about a bunch of things it should not warn about.
#       It should get smarter and look at only the remote named upstream.
for repo in $unexpected_repos; do
    echo "WARNING: Found unexpected cloned repository: $repo"
done

for repo in $missing_repos; do
    git clone $repo
done
