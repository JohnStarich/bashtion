#!/usr/bin/env bash

import test/assert
import utils/map

declare -A a b r

assert map.read_set a <<<$'hey\nthere'
assert map.read_set b <<<'hey'

assert.equal 'set' "${a[hey]+set}"
assert.equal 'set' "${a[there]+set}"
assert.equal 'set' "${b[hey]+set}"
assert.not_equal 'set' "${b[there]+set}"

assert map.diff_keys a b r
assert.not_equal 'set' "${r[hey]+set}"
assert.equal 'set' "${r[there]+set}"
