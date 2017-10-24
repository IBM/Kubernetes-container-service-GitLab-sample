#!/bin/bash -e

# shellcheck disable=SC1090
source "$(dirname "$0")"/../scripts/resources.sh

if find . -name '*.sh' -print0 | xargs -n1 -0 shellcheck -x -s bash; then
    test_passed "$0"
else
    test_failed "$0"
fi
