#!/usr/bin/env bash

# Enable additional shell options to test for correctness.

# Error if a variable is used before being set.
set -u

## Bootstrap framework
LOG_LEVEL=${LOG_LEVEL:-debug}

import lib/test/test

function run_file() {
    local -
    # Exit early on failure, also disable job control to assist tests with output and lastpipe options
    set -e +m
    local file=$1
    # shellcheck disable=SC1090
    source "$file"
}

if [[ $# != 0 ]]; then
    test start "$*"
    # shellcheck disable=SC1090
    source "$*" || true
else
    for test_file in tests/**/*.sh; do
        test start "$test_file"
        run_file "$test_file" || true
    done
fi

test stats
test require_no_failures
