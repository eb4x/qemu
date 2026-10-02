#!/bin/sh
# Make the upstream-named branches of a fork equal to upstream QEMU.
#
#   sync-mirrors.sh <fork-push-url> <branch>...
#
# These branches are pure mirrors that nobody commits to, so they are
# force-pushed: that also follows upstream when it rewrites a branch
# (staging-* can be). Extra `git push` arguments can be passed in PUSH_OPTS.

set -eu

upstream=${UPSTREAM:-https://gitlab.com/qemu-project/qemu.git}
fork=$1
shift

tip() {
    git ls-remote "$1" "refs/heads/$2" | cut -f1
}

refspecs=
for b in "$@"; do
    up=$(tip "$upstream" "$b")
    if [ -z "$up" ]; then
        echo "error: upstream has no branch $b" >&2
        exit 1
    fi
    mine=$(tip "$fork" "$b")
    if [ "$up" = "$mine" ]; then
        echo "$b: up to date ($up)"
    else
        echo "$b: ${mine:-<missing>} -> $up"
        refspecs="$refspecs +refs/heads/$b:refs/heads/$b"
    fi
done

if [ -z "$refspecs" ]; then
    echo "Nothing to do."
    exit 0
fi

# Fetch full history: the push then only sends what the fork lacks.
repo=$(mktemp -d)
git init -q --bare "$repo"
# shellcheck disable=SC2086
git -C "$repo" fetch -q --no-tags "$upstream" $refspecs
# shellcheck disable=SC2086
git -C "$repo" push -q ${PUSH_OPTS:-} "$fork" $refspecs
