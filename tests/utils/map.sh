#!/usr/bin/env bash

import test/assert
import utils/map

declare -A a b r

map.read_set a <<<$'hey\nthere'
map.read_set b <<<'hey'

assert.equal 'declare -A a=([hey]="" [there]="" )' "$(declare -p a)"
assert.equal 'declare -A b=([hey]="" )' "$(declare -p b)"

map.diff_keys a b r
assert.equal 'declare -A r=([there]="" )' "$(declare -p r)"
