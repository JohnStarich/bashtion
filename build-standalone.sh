#!/usr/bin/env bash
# Build an all-in-one script to use Bashtion
# Do not use this file in your own scripts!

set -euxo pipefail
shopt -s globstar nullglob

output_file=./try-bashtion.sh

{
cat <<EOT
#!/usr/bin/env bash
# Bootstrap Try Bashtion
#
# Automatically generated with bashtion/$(basename "$0")

[ -n "\$BASH_VERSINFO" ] && [ "\${BASH_VERSINFO[0]}" -lt 4 ] && echo "This library requires Bash 4 or higher" && exit 1 || true

if [[ "\${BASHTION_BOOTSTRAPPED:-}" == true ]]; then
    logger warn 'Already bootstrapped. Skipping...'
    return 0
fi

# Set shell options for running in a production environment.
# We strongly recommend you use these options.
# Only disable if this is NOT running in production.
# To test interactively, use a login shell (i.e. \`bash -l\`)
if [[ "\${UNSAFE:-}" != thisisnotproduction ]]; then
    if ! shopt -q login_shell; then
        # Exit if any command returns a non-zero code.
        set -e
    fi
    # Fail a pipe command if any of the commands fail.
    set -o pipefail
    # Allow aliases for more advanced behavior.
    shopt -s expand_aliases
fi

EOT

# Add base modules to bootstrap
# Modules to load (in-order)
preloaded_modules=(
    ./lib/utils/string.sh
    ./lib/utils/modules.sh
)

preloaded_plugins=(
    ./out/namespace
    ./out/logger
)

for plugin in "${preloaded_plugins[@]}"; do
    curl -fsSL "https://github.com/JohnStarich/goenable/releases/download/0.2.0/goenable-$(uname -s)-$(uname -m).so" > "${bashtion_root}"/cache/goenable.so
done

function clean_module() {
    local file=$1
    local import_path=${file#./lib/}
    import_path=${import_path%.sh}
    echo "$import_path"
}

# First cache all imports since they will all be available at runtime
for file in ./lib/utils/**/*.sh; do
    echo "modules._cache_import '$(clean_module "$file")'"
done

echo

for file in ./lib/utils/**/*.sh; do
    if [[ "${preloaded_modules[*]}" != *"$file"* ]]; then
        cat "$file"
        helper_name=$(basename "$(clean_module "$file")")
        echo "modules._create_module_helper '$helper_name'"
    fi
done

echo
echo declare -gr BASHTION_BOOTSTRAPPED=true
echo "logger.debug 'Fortification complete.'"

} > "$output_file"
