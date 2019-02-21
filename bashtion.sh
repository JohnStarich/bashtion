#!/usr/bin/env bash
# Bootstrap Bashtion

# Prevent shellcheck rules from being global
true

# Temporarily disable some checks to fail gracefully when invoking the wrong shell.
# shellcheck disable=SC2015,SC2128
[ -n "$BASH_VERSINFO" ] && [ "${BASH_VERSINFO[0]}" -lt 4 ] && echo "This library requires Bash 4 or higher" && exit 1 || true

if [[ "${BASHTION_BOOTSTRAPPED:-}" == true ]]; then
    logger warn 'Already bootstrapped. Skipping...'
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
bashtion_root=${BASH_SOURCE[0]%/*}
if [[ "${bashtion_root}" == "${BASH_SOURCE[0]}" ]]; then
    # Presumably sourcing from the same directory
    bashtion_root=$(pwd -P)
elif [[ ! -d "${bashtion_root}" ]]; then
    echo 'Failed to find Bashtion source directory.'
    return 1
else
    bashtion_root=$(cd "${BASH_SOURCE[0]%/*}" && pwd -P)
fi

# Immediately try and make our lives easier: include a simple logger and an importer.
if [[ ! -f "${bashtion_root}"/cache/goenable.so ]]; then
    mkdir -p "${bashtion_root}"/cache
    curl -fsSL "https://github.com/JohnStarich/goenable/releases/download/0.2.0/goenable-$(uname -s)-$(uname -m).so" > "${bashtion_root}"/cache/goenable.so
fi
enable -f "${bashtion_root}"/cache/goenable.so goenable

prepare_plugin() {
    local plugin=$1
    local plugin_loc plugin_output
    plugin_loc="${bashtion_root}/out/${plugin}"
    # TODO download plugins and use cache dir
    #if [[ ! -f "$plugin_loc" ]]; then
    #    curl -fsSL "https://github.com/JohnStarich/bashtion/releases/download/0.1.0/${plugin}-$(uname -s)-$(uname -m)" > "$plugin_loc"
    #fi
    goenable load "$plugin_loc" plugin_output
    eval "${plugin_output}"
}

for plugin in namespace logger; do
    prepare_plugin "$plugin"
done

# shellcheck source=lib/utils/modules.sh
source "${bashtion_root}"/lib/utils/modules.sh

PATH="$PATH:${bashtion_root}/lib"

# Erase bootstrapped vars
unset -f prepare_plugin
unset bashtion_root

#import utils/string
#import utils/exception

declare -gr BASHTION_BOOTSTRAPPED=true
logger debug 'Fortification complete.'
