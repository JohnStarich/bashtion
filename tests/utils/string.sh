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


assert.equal '  ' "$(string.pad 2)"
assert.equal '' "$(string.pad 0)"


assert.equal 'hi' "$(string.nth_token 0 hi there)"
assert.equal 'there' "$(string.nth_token 1 hi there)"
assert.equal 'there' "$(string.nth_token -1 hi there)"
assert.equal 'hi' "$(string.nth_token -2 hi there)"
assert.false string.nth_token -3 hi there
assert.false string.nth_token 2 hi there

assert.equal 'hi' "$(IFS=: string.nth_token 0 "hi:there folks")"
assert.equal 'there folks' "$(IFS=: string.nth_token 1 "hi:there folks")"


assert.equal 'hi' "$(string.filter 'hi' $'hi\nthere\nbob')"
assert.equal 'there' "$(string.filter 'there' $'hi\nthere\nbob')"
assert.equal $'ok\nokay' "$(string.filter 'ok' $'ok\nokay\nalright then')"
assert.equal $'ok\nokay' "$(echo $'ok\nokay\nalright then' | string.filter 'ok')"


assert.equal $'ok\nalright' "$(string.filter_not 'okay' $'ok\nokay\nalright')"
assert.equal 'alright' "$(string.filter_not 'ok' $'ok\nokay\nalright')"
assert.equal 'alright then' "$(echo $'ok\nokay\nalright then' | string.filter_not 'ok')"
