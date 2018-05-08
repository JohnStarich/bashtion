#!/usr/bin/env bash

# Enable additional shell options to test for correctness.

# Error if a variable is used before being set.
set -u

## Bootstrap framework
LOG_LEVEL=${LOG_LEVEL:-all}
# shellcheck source=bootstrap.sh
source "${BASH_SOURCE[0]%/*}/bootstrap.sh"

import test/assert

function reset_flags() {
    # Reset flags if tests decide to change them
    set -eu +x
    logger.set_level "$LOG_LEVEL"
}

for test in tests/**/*.sh; do
    reset_flags
    # shellcheck disable=SC1090
    source "$test" || true
done

reset_flags
assert.stats
