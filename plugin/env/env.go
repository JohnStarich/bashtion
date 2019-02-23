package env

var (
	// Getenv ...
	Getenv func(key string) string
	// Setenv ...
	Setenv func(key, value string) error
	// Unsetenv ...
	Unsetenv func(key string) error
)
