#!/usr/bin/env bash

# Enable additional shell options to test for correctness.

# Error if a variable is used before being set.
set -u

## Bootstrap framework
LOG_LEVEL=${LOG_LEVEL:-all}
# shellcheck source=bashtion.sh
source "${BASH_SOURCE[0]%/*}/bashtion.sh"

import test/test


for test in tests/**/*.sh; do
    test.init "$test"
    # shellcheck disable=SC1090
    source "$test" || true
done

test.stats
