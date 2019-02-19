package main

import (
	"bytes"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/johnstarich/goenable/env"
	"github.com/johnstarich/goenable/stringutil"
	"mvdan.cc/sh/syntax"
)

const (
	functionPrefixSeparator = "-"
	variablePrefixSeparator = "_"
)

// Usage returns the full set of documentation for this plugin
func Usage() string {
	return strings.TrimSpace(`
Usage: namespace ENV_VAR SCRIPT_FILE
'namespace' is a utility to load scripts and make them namespace-friendly.
Namespaces make it easier to create reusable modules and don't conflict in a global bash context.
`)
}

// Load runs any set up required by this plugin
func Load() error {
	return nil
}

// Unload runs any tear down required by this plugin
func Unload() {
}

// Run executes this plugin with the given arguments
func Run(args []string) (int, error) {
	if len(args) != 2 {
		return 2, errors.New(Usage())
	}
	outputEnvVar, fileName := args[0], args[1]
	// ensure PATH is consistent
	if err := env.Setenv("PATH", env.Getenv("PATH")); err != nil {
		return 1, err
	}
	filePath, err := exec.LookPath(fileName)
	if err != nil {
		// attempt to find file at the given path
		if !strings.HasSuffix(fileName, ".sh") {
			var errExt error
			filePath, errExt = exec.LookPath(fileName + ".sh")
			if errExt != nil {
				return 2, fmt.Errorf("Error locating '%s'. Paths attempted:\n\t%s\n\t%s", fileName, err, errExt)
			}
		} else {
			return 2, err
		}
	}
	reader, err := os.Open(filePath)
	if err != nil {
		return 1, err
	}
	defer reader.Close()

	name := filepath.Base(fileName)
	name = strings.TrimSuffix(name, filepath.Ext(name))
	parser := syntax.NewParser()
	f, err := parser.Parse(reader, name)
	if err != nil {
		return 1, err
	}

	extraScript := mutate(f, name)
	buf := bytes.NewBufferString(extraScript)
	printer := syntax.NewPrinter()
	printer.Print(buf, f)
	env.Setenv(outputEnvVar, buf.String())
	return 0, nil
}

func mutate(f *syntax.File, name string) string {
	extraScript := ""
	functionNames := make(map[string]bool)
	globalVarNames := make(map[string]bool)
	syntax.Walk(f, func(node syntax.Node) bool {
		switch x := node.(type) {
		case *syntax.Block:
			// only scan for 'declare -g' statements when inside blocks
			syntax.Walk(node, func(blockNode syntax.Node) bool {
				switch y := blockNode.(type) {
				case *syntax.DeclClause:
					if y.Variant.Value != "declare" {
						return true
					}
					foundGlobalOpt := false
					for _, opt := range y.Opts {
						if strings.ContainsRune(opt.Lit(), 'g') {
							foundGlobalOpt = true
							break
						}
					}
					if !foundGlobalOpt {
						return true
					}
					for _, a := range y.Assigns {
						if a.Name == nil {
							globalVarNames[a.Value.Lit()] = true
						} else {
							globalVarNames[a.Name.Value] = true
						}
					}
				}
				return true
			})
			// don't look for globals inside blocks
			return false
		case *syntax.FuncDecl:
			// find and prefix function names (replace function calls later)
			functionNames[x.Name.Value] = true
			x.Name.Value = name + functionPrefixSeparator + x.Name.Value
		case *syntax.Assign:
			// find global variable names
			if x.Name == nil {
				globalVarNames[x.Value.Lit()] = true
			} else {
				globalVarNames[x.Name.Value] = true
			}
		}
		return true
	})

	prefix := name + functionPrefixSeparator
	allFunctionNames := ""
	for name := range functionNames {
		allFunctionNames += " " + stringutil.SingleQuote(name)
	}

	if !functionNames["usage"] {
		functionNames["usage"] = true
		extraScript += stringutil.Dedent(`
			` + prefix + `usage() {
				echo 'Usage: ` + name + ` COMMAND' >&2
				echo 'Available commands: '` + allFunctionNames + ` >&2
			}
		`)
	}
	if !functionNames[name] {
		extraScript += stringutil.Dedent(`
			` + name + `() {
				local subCommand=$1
				if [[ -z "$subCommand" ]]; then
					` + prefix + `usage
					return 2
				fi
				shift
				if ! command -v "` + prefix + `${subCommand}" >/dev/null; then
					echo "Invalid subcommand: ${subCommand}" >&2
					` + prefix + `usage
					return 2
				fi
				"` + prefix + `${subCommand}" "$@"
			}
		`)
	}
	if !functionNames["complete"] {
		extraScript += stringutil.Dedent(`
			` + prefix + `complete() {
				local options=(` + allFunctionNames + `)
				local prev=${COMP_WORDS[COMP_CWORD - 1]}
				if [[ "$prev" != ` + name + ` ]]; then
					return
				fi
				COMPREPLY+=( $(compgen -W "${options[*]}" -- "${COMP_WORDS[COMP_CWORD]}") )
			}
		`)
	}
	extraScript += fmt.Sprintf("complete -F %s %s\n\n", prefix+"complete", name)
	syntax.Walk(f, func(node syntax.Node) bool {
		switch x := node.(type) {
		case *syntax.CallExpr:
			// replace functions names with prefixed versions
			if len(x.Args) > 0 && len(x.Args[0].Parts) == 1 {
				switch funcName := x.Args[0].Parts[0].(type) {
				case *syntax.Lit:
					if functionNames[funcName.Value] {
						funcName.Value = name + functionPrefixSeparator + funcName.Value
					}
				}
			}
		case *syntax.ParamExp:
			// replace global variable names with prefixed versions
			if globalVarNames[x.Param.Value] {
				x.Param.Value = name + variablePrefixSeparator + x.Param.Value
			}
		case *syntax.Assign:
			// replace global variable names with prefixed versions
			if globalVarNames[x.Name.Value] {
				x.Name.Value = name + variablePrefixSeparator + x.Name.Value
			}
		}
		return true
	})
	return extraScript
}

func main() {}
