# Bashtion

A stronghold for using Bash in production

Build reusable Bash modules painlessly. Bashtion makes it easy to modularize existing code and write end-to-end tests.

## Features

* Makes it easy to modularize existing code bases
* Provides an `import` function to easily use other modules without worrying about things like import cycles
* Contains a test framework, useful for end-to-end testing (and it is used to [test Bashtion](tests/) itself)
* Includes a built-in logger and other common utilities

Bashtion is geared toward use in production environments where code reuse and finding bugs becomes critical for success.
This framework is still under development, so if you have any suggestions, feel free to [make an issue](https://github.com/JohnStarich/bashtion/issues/new)!

## Getting Started

To use Bashtion, simply source `bootstrap.sh` in the root of this repository. You must be using at least Bash 4.

Include this in a script or use it in your `~/.bash_profile`. Here's an example start script:

```bash
#!/usr/bin/env bash
source "$WORKSPACE/bashtion/bootstrap.sh"

import utils/logger

logger.info 'Hello world!'
```

After sourcing the `bootstrap.sh` script, you're good to go! Both `utils/logger` and `utils/modules` are imported by default so you can get to the good stuff right away.

## Writing your own modules

You can create your very own reusable modules!

For example, this one simply checks if your internet works `./modules/network/internet.sh`:

```bash
# Use included retry module
import utils/retrier

function internet.status() {
    retry curl http://google.com
}
```

The `import` function prevents import cycles and can be used as a drop-in replacement for `source`.

To use shorter import paths, you can register directories like `./modules` as an import path.
This start script registers `./modules` and calls our internet status checker:

```bash
#!/usr/bin/env bash
# Run Bashtion's startup script
source "$WORKSPACE/bashtion/bootstrap.sh"
# Register your module
modules.register_import_path "$PWD/modules"

# Finally, import and run it!
import network/internet

internet.status
```

## Writing your own tests

Tests are as simple as importing `test/assert` and calling `assert.stats` at the end of your tests.

Check out this simple test suite:

```bash
import test/assert
import utils/retrier


assert echo hello world!
assert.true echo hey!

assert.false ls /missing

assert.equal 'expected' "$(echo expected)"
assert.not_equal 'unexpected' "$(echo surprise!)"

# done! let's print our test results.
assert.stats
# Output:
#
# [ INFO] Test Results:
# [ INFO] 4/4 (100%) tests passed. 0 tests failed.
# [ INFO] All tests passed.
```

## How do I poke around this library?

Every module has its own file inside of [lib](lib/) or its subdirectories. If you see a module you want in there, just import it using its relative path from `lib`. The retrier is located in `./lib/utils/retrier.sh` so you would run `import utils/retrier`.

If you want to find out which commands are available for a module, the easiest way is to run the function with that module's name.
For example, run `logger` and it will print out all available logger commands like `logger.info` and `logger.error`.
