#!/usr/bin/env bash

import test/assert


logger.set_file /dev/stdout
logger.set_level all
assert logger.debug 'hello world!' >/dev/null
assert.equal '[DEBUG] hello world!' "$(logger.debug 'hello world!')"
assert.equal '[ WARN] hello world!' "$(logger.warn 'hello world!')"

logger.set_level info
assert.equal '' "$(logger.debug test)"
assert.not_equal '' "$(logger.info test)"

logger.set_level error
assert.equal '' "$(logger.debug test)"
assert.equal '' "$(logger.info test)"
assert.equal '' "$(logger.warn test)"
assert.not_equal '' "$(logger.error test)"
logger.set_level "$LOG_LEVEL"
