#!/usr/bin/env bash
# Bootstrap the library for use of standard functionality.

# Exit if any command returns a non-zero code.
set -e

# Temporarily disable some checks to fail gracefully when invoking the wrong shell.
# shellcheck disable=SC2015,SC2128
[ -n "$BASH_VERSINFO" ] && [ "${BASH_VERSINFO[0]}" -lt 4 ] && echo "This library requires Bash 4 or higher" && exit 1 || true

if [[ "$BOOTSTRAPPED" == true ]]; then
    logger.warn 'Already bootstrapped. Skipping...'
    return 0
fi

# Fail a pipe command if any of the commands fail
set -o pipefail
# Error if a variable is used before being set.
set -u
# Allow aliases for more advanced behavior.
shopt -s expand_aliases

# Get absolute path to the repository root
__repo_root=$(cd "${BASH_SOURCE[0]%/*}" && pwd -P)

# Immediately try and make our lives easier: include a simple logger and an importer.
# shellcheck source=lib/utils/logger.sh
source "${__repo_root}"/lib/utils/logger.sh
logger.init
# shellcheck source=lib/utils/modules.sh
source "${__repo_root}"/lib/utils/modules.sh

BOOTSTRAPPED=true
logger.debug 'Bootstrap complete.'
