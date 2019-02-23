package main

import (
	"errors"
	"strings"

	"github.com/johnstarich/bashtion/plugin/command"
	"github.com/johnstarich/bashtion/plugin/env"
	"github.com/johnstarich/bashtion/plugin/logger"
	"github.com/johnstarich/bashtion/plugin/namespace"
	"github.com/johnstarich/bashtion/plugin/usage"
)

var (
	errUsage       = errors.New(Usage())
	loadedCommands = make(map[string]bool)

	commands = map[string]command.Command{
		"logger":    &logger.Logger{},
		"namespace": &namespace.Namespace{},
	}

	helpers func(helper string) (interface{}, bool)
)

// Usage returns the full set of documentation for this plugin
func Usage() string {
	return strings.TrimSpace(`
bashtion run COMMAND
bashtion load ENV_VAR COMMAND
`)
}

// Load runs any set up required by this plugin
func Load(h func(string) (interface{}, bool)) error {
	helpers = h
	getenv, ok := helpers("Getenv")
	if !ok {
		return errors.New("Missing helper for Getenv")
	}
	env.Getenv = getenv.(func(string) string)
	setenv, ok := helpers("Setenv")
	if !ok {
		return errors.New("Missing helper for Setenv")
	}
	env.Setenv = setenv.(func(string, string) error)
	unsetenv, ok := helpers("Unsetenv")
	if !ok {
		return errors.New("Missing helper for Unsetenv")
	}
	env.Unsetenv = unsetenv.(func(string) error)
	return nil
}

// Unload runs any tear down required by this plugin
func Unload() {
	for name := range loadedCommands {
		commands[name].Unload()
	}
}

// Run executes this plugin with the given arguments
func Run(args []string) (int, error) {
	if len(args) == 0 {
		return 2, errUsage
	}
	action, args := args[0], args[1:]

	switch action {
	case "run":
		if len(args) < 1 {
			return 2, errUsage
		}
		command := args[0]
		cmd, ok := commands[command]
		if !ok {
			return usage.HandleError(usage.Errorf("Invalid subcommand: " + command))
		}
		if !loadedCommands[command] {
			if err := cmd.Load(); err != nil {
				return usage.HandleError(err)
			}
			loadedCommands[command] = true
		}
		return usage.HandleError(cmd.Run(args[1:]))
	case "load":
		if len(args) < 2 {
			return 2, errUsage
		}
		envVar, command := args[0], args[1]
		cmd, ok := commands[command]
		if !ok {
			return usage.HandleError(usage.Errorf("Invalid subcommand: " + command))
		}
		if err := cmd.Load(); err != nil {
			return usage.HandleError(err)
		}
		loadedCommands[command] = true
		funcScript := command + `() { bashtion run ` + command + ` "$@"; }` + "\n"
		env.Setenv(envVar, funcScript)
		return 0, nil
	default:
		return 2, errUsage
	}
}

func main() {}
