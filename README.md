# Bashtion

A stronghold for using Bash in production

Bashtion makes it easy to modularize existing code and write end-to-end tests.
Lessen the risk of polluting globals while also running `source` for as many Bash scripts as you like.

## Features

* Provides an `import` function to easily source scripts. It automatically:
    - Modularizes existing Bash scripts
    - Prevents import cycles
* Contains a test framework, useful for end-to-end testing (and it is used to [test Bashtion](tests/) itself)
* Colorized stack traces for debugging
* Includes a built-in logger and other common utilities

Bashtion is geared toward use in production environments where code reuse and finding bugs becomes critical for success.
This framework is still under development, so if you have any suggestions, then [make an issue](https://github.com/JohnStarich/bashtion/issues/new)!

## Try it

Run the following command in your shell to try it out.

```bash
source <(curl -fsSL -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/JohnStarich/bashtion/releases/latest | grep browser_download_url | cut -d '"' -f 4 | xargs curl -fsSL)
```

The above script checks for the latest stable release and then sources it. Please note that try-bashtion.sh is not recommended for production builds because it includes the _entire_ standard library. (You should only import things you need.)

## Getting Started

To use Bashtion, simply source `bashtion.sh` in the root of this repository. You must be using at least Bash 4.

Include this in a script or use it in your `~/.bash_profile`. Here's an example start script:

```bash
#!/usr/bin/env bash
source "$WORKSPACE/bashtion/bashtion.sh"

import "$WORKSPACE/bashtion/lib/utils/colors"

colors color green
echo Hello world!
colors color reset
logger info 'Loggers are neat :)'
```

After sourcing the `bashtion.sh` script, you're good to go! Both `logger` and `import` are ready by default so you can get to the good stuff right away.

## Writing your own modules

You can create your very own reusable modules!

For example, this one simply checks if your internet works `./modules/internet.sh`:

```bash
# Use included retry module
import "$WORKSPACE/bashtion/lib/utils/retrier"

function status() {
    retrier retry curl http://google.com
}
```

The `import` function can be used as a drop-in replacement for `source` and it prevents import cycles.

To use shorter import paths, you can add directories like `./modules` to your `$PATH`.
This start script registers `./modules` as an import on `$PATH`, then calls our internet status checker:

```bash
#!/usr/bin/env bash
# Run Bashtion's startup script
source "$WORKSPACE/bashtion/bashtion.sh"
# Register your modules directory
PATH="$PATH:$PWD/modules"

# Finally, import and run it!
import internet

internet status
```

## Writing your own tests

Tests are as simple as importing `lib/test/assert` and calling `assert stats` at the end of your tests.

For a little more completeness, take a look at `lib/test/test`. For example, check out this simple test suite:

```bash
import lib/test/assert
import lib/test/test
import lib/utils/retrier


test start "Simple test"

assert true echo hello world!

assert false ls /missing

assert equal 'expected' "$(echo expected)"
assert not_equal 'unexpected' "$(echo surprise!)"

# done! let's print our test results.
test stats
# Output:
#
# [ INFO] Test Results:
# [ INFO] 4/4 (100%) tests passed. 0 tests failed.
# [ INFO] All tests passed.
```

For a more comprehensive test runner, check out the one we use to test Bashtion [here](test.sh).

## How do I poke around this library?

Every module has its own file inside of [lib](lib/) or its subdirectories. If you see a module you want in there, just import it. The retrier is located in `./lib/utils/retrier.sh` so you would run `import ./lib/utils/retrier`.

If you want to find out which commands are available for a module, the easiest way is to run the function with that module's name.
For example, run `logger` and it will print out all available logger commands like `logger info` and `logger error`.

## Learn more

Bashtion is made possible by [JohnStarich/goenable](https://github.com/JohnStarich/goenable) and [mvdan/sh](https://github.com/mvdan/sh). Check them out to learn more.
