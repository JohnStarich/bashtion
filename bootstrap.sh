#!/usr/bin/env bash
# Bootstrap the library for use of standard functionality.

# Prevent shellcheck rules from being global
true

# Temporarily disable some checks to fail gracefully when invoking the wrong shell.
# shellcheck disable=SC2015,SC2128
[ -n "$BASH_VERSINFO" ] && [ "${BASH_VERSINFO[0]}" -lt 4 ] && echo "This library requires Bash 4 or higher" && exit 1 || true

if [[ "${BOOTSTRAPPED:-}" == true ]]; then
    logger.warn 'Already bootstrapped. Skipping...'
    return 0
fi

# Set shell options for running in a production environment.
# We strongly recommend you use these options.
# Only disable if this is NOT running in production.
# To test interactively, use a login shell (i.e. `bash -l`)
if [[ "${UNSAFE:-}" != thisisnotproduction ]]; then
    if ! shopt -q login_shell; then
        # Exit if any command returns a non-zero code.
        set -e
    fi
    # Fail a pipe command if any of the commands fail.
    set -o pipefail
    # Allow aliases for more advanced behavior.
    shopt -s expand_aliases
fi

# Get absolute path to the repository root
__repo_root=${BASH_SOURCE[0]%/*}
if [[ "${__repo_root}" == "${BASH_SOURCE[0]}" ]]; then
    # Presumably sourcing from the same directory
    __repo_root=$(pwd -P)
elif [[ ! -d "${__repo_root}" ]]; then
    echo 'Failed to find bootstrap source directory.'
    return 1
else
    __repo_root=$(cd "${BASH_SOURCE[0]%/*}" && pwd -P)
fi

# Immediately try and make our lives easier: include a simple logger and an importer.
# shellcheck source=lib/utils/logger.sh
source "${__repo_root}"/lib/utils/logger.sh
logger.init
# shellcheck source=lib/utils/modules.sh
source "${__repo_root}"/lib/utils/modules.sh

BOOTSTRAPPED=true
logger.debug 'Bootstrap complete.'
