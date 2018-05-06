#!/usr/bin/env bash
# Bootstrap the library for use of standard functionality.

# Exit if any command returns a non-zero code.
set -e

# Temporarily disable some checks to fail gracefully when invoking the wrong shell.
# shellcheck disable=SC2015,SC2128
[ -n "$BASH_VERSINFO" ] && [ "${BASH_VERSINFO[0]}" -lt 4 ] && echo "This library requires Bash 4 or higher" && exit 1 || true

# Fail a pipe command if any of the commands fail
set -o pipefail
# Error if a variable is used before being set.
set -u
# Allow aliases for more advanced behavior.
shopt -s expand_aliases

# Get absolute path to the repository root
__repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)

# Immediately try and make our lives easier: include a simple logger and an importer.
# shellcheck source=utils/logger.sh
source "${__repo_root}"/utils/logger.sh
# shellcheck source=utils/modules.sh
source "${__repo_root}"/utils/modules.sh

logger.debug 'Bootstrap complete.'
eval "$*"
