#!/usr/bin/env bash

import lib/test/assert


shopt -s lastpipe  # enable reading builtin's output

logger level debug
assert true logger debug 'hello world!' >/dev/null

logger debug 'hello world!' |& read -r line
assert strip-color line
assert equal $'DEBUG\thello world!' "$line"

logger warn 'hello world!' |& read -r line
assert strip-color line
assert equal $'WARN\thello world!' "$line"


logger level info
logger debug test |& read -r line || true
assert equal '' "$line"
logger info test |& read -r line || true
assert not_equal '' "$line"

logger level error
logger debug test |& read -r line || true
assert equal '' "$line"
logger info test |& read -r line || true
assert equal '' "$line"
logger warn test |& read -r line || true
assert equal '' "$line"
logger error test |& read -r line
assert not_equal '' "$line"
logger level "$LOG_LEVEL"
