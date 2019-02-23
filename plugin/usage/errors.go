package usage

import "fmt"

// Error indicates a usage error occurred.
// Usage documentation should be printed and the CLI should return exit code 2.
type Error error

// Errorf wraps fmt.Errorf and returns a usage error
func Errorf(format string, a ...interface{}) error {
	return Error(fmt.Errorf(format, a...))
}

// HandleError transforms an error into a return code and the error.
// Makes error handling easier in the plugin Run func.
func HandleError(err error) (int, error) {
	switch err.(type) {
	case Error:
		return 2, err
	case nil:
		return 0, nil
	default:
		return 1, err
	}
}
