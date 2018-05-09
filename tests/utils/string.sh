#!/usr/bin/env bash

import test/assert
import utils/string


assert.equal 'path.sh' "$(string.basename '/root/path.sh')"
assert.equal 'path.sh' "$(string.basename 'root/path.sh')"
assert.equal 'path.sh' "$(string.basename '/path.sh')"
assert.equal 'path.sh' "$(string.basename 'path.sh')"
assert.equal 'path with spaces.sh' "$(string.basename '/root/path with spaces.sh')"
assert.equal 'path.sh' "$(string.basename '/root with spaces/path.sh')"
assert.equal 'path' "$(string.basename '/root/path///')"
assert.equal 'path' "$(string.basename '///path')"
assert.equal '/' "$(string.basename '///')"
assert.equal '' "$(string.basename '')"


assert.equal '/root' "$(string.dirname '/root/path.sh')"
assert.equal 'root' "$(string.dirname 'root/path.sh')"
assert.equal '/' "$(string.dirname '/path.sh')"
assert.equal '.' "$(string.dirname 'path.sh')"
assert.equal '/root' "$(string.dirname '/root/path with spaces.sh')"
assert.equal '/root with spaces' "$(string.dirname '/root with spaces/path.sh')"
assert.equal '/root' "$(string.dirname '/root/path///')"
assert.equal '/' "$(string.dirname '///path')"
assert.equal '/' "$(string.dirname '///')"
assert.equal '.' "$(string.dirname '')"
