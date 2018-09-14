#!/usr/bin/env bash

import test/assert

logger.set_file /dev/stdout
logger.set_level warn

assert.equal '' "$(import tests/modules/basic)"

modules.set_warning_limit 100
# check single bad module
output=$(import tests/modules/bad-names)
assert.contains "$output" 'Functions should be namespaced'
assert.contains "$output" not_ok
assert.contains "$output" nope
assert.contains "$output" na_ah
assert.contains "$output" not_gonna_work
assert.contains "$output" not_this_either
assert.contains "$output" or_this
assert.contains "$output" or_even_this
assert.not_contains "$output" bad-names.ok

# check import chain
assert.equal '' "$(import tests/modules/chainA)"

# reset environment
modules.set_warning_limit
