#!/usr/bin/env bash

# Enable additional shell options to test for correctness.

# Error if a variable is used before being set.
set -u

## Bootstrap framework
LOG_LEVEL=${LOG_LEVEL:-all}
# shellcheck source=bashtion.sh
source "${BASH_SOURCE[0]%/*}/bashtion.sh"

import test/assert


function reset_flags() {
    # Reset flags if tests decide to change them
    set -eu +x
    logger.set_level "$LOG_LEVEL"
}

VERBOSE=${VERBOSE:-false}
test_space=''
if [[ "$VERBOSE" != true ]] && which mktemp >/dev/null && which mkfifo >/dev/null; then
    test_space=$(mktemp -d)
    rc_pipe="$test_space"/rc_pipe
    output_pipe="$test_space"/output_pipe
    mkfifo "$rc_pipe"
    mkfifo "$output_pipe"
fi

for test in tests/**/*.sh; do
    reset_flags
    if [[ -n "$test_space" ]]; then
        {
            output=$(<"$output_pipe")
            rc=$(<"$rc_pipe")
            if [[ "$rc" == 0 ]]; then
                echo "$output" >/dev/null
            else
                echo "$output"
            fi
        } &
        {
            # shellcheck disable=SC1090
            source "$test" &>"$output_pipe"
            echo $? >"$rc_pipe"
        }
        wait
    else
        # shellcheck disable=SC1090
        source "$test" || true
    fi
done

if [[ -n "$test_space" ]]; then
    rm -rf "$test_space"
fi

reset_flags
assert.stats
