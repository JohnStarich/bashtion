# bashtion

A stronghold for using Bash in production

## Features

* Provides an `import` function to easily include other modules
* Built-in logger and other common utilities
* Built-in test framework

This framework is still under development, but is geared toward use in production environments. If you have any suggestions, feel free to [make an issue](https://github.com/JohnStarich/bashtion/issues/new)!

## Usage

To use Bashtion, simply source `bootstrap.sh` in the root of this repository. You must be using at least Bash 4.

Here's an example start script:

```bash
#!/usr/bin/env bash
source "$WORKSPACE/bashtion/bootstrap.sh"

import utils/logger

logger.info 'Hello world!'
```

## Writing your own modules

You can create your very own modules!

For example, this one checks if your internet works `./modules/network/internet.sh`:

```bash
# Use included retry module
import utils/retrier

function internet.status() {
    retry curl http://google.com
}
```

To use your own modules, register the module root path in your start script:

```bash
#!/usr/bin/env bash
# Run Bashtion's startup script
source "$WORKSPACE/bashtion/bootstrap.sh"

# Register your module
import utils/modules

modules.register_import_path "$PWD/modules"

# Finally, import and run it!
import network/internet

internet.status
```

_Stay tuned for more documentation..._
