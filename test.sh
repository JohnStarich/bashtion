#!/usr/bin/env bash

# Enable additional shell options to test for correctness.

# Error if a variable is used before being set.
set -u

## Bootstrap framework
LOG_LEVEL=${LOG_LEVEL:-all}
# shellcheck source=bashtion.sh
source "${BASH_SOURCE[0]%/*}/bashtion.sh"

import test/test


if [[ $# != 0 ]]; then
    test.start "$*"
    # shellcheck disable=SC1090
    source "$*" || true
else
    for test in tests/**/*.sh; do
    #for test in $(find tests -type f -name '*.sh' | sort -R); do
        test.start "$test"
        # shellcheck disable=SC1090
        source "$test" || true
    done
fi

test.stats
test.require_no_failures
