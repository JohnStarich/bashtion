package namespace

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/johnstarich/bashtion/plugin/command"
	"github.com/johnstarich/bashtion/plugin/usage"
	"github.com/johnstarich/goenable/env"
	"github.com/johnstarich/goenable/stringutil"
	"mvdan.cc/sh/syntax"
)

const (
	functionPrefixSeparator = "-"
	variablePrefixSeparator = "_"
)

var (
	importCache = make(map[string]bool)
)

// Namespace is part of an import function that helps reduce global name collisions
type Namespace struct {
	command.Command
}

// Usage returns the full set of documentation for this plugin
func (n *Namespace) Usage() string {
	return strings.TrimSpace(`
Usage: namespace ENV_VAR SCRIPT_FILE
'namespace' is a utility to load scripts and make them namespace-friendly.
Namespaces make it easier to create reusable modules and don't conflict in a global bash context.
`)
}

// Load runs any set up required by this plugin
func (n *Namespace) Load() error {
	return nil
}

// Unload runs any tear down required by this plugin
func (n *Namespace) Unload() {
}

// Run executes this plugin with the given arguments
func (n *Namespace) Run(args []string) error {
	if len(args) != 2 {
		return usage.Errorf(n.Usage())
	}
	outputEnvVar, fileName := args[0], args[1]
	// ensure PATH is consistent with C.getenv before exec.LookPath
	if err := env.Setenv("PATH", env.Getenv("PATH")); err != nil {
		return err
	}
	filePath, err := exec.LookPath(fileName)
	if err != nil {
		// attempt to find file at the given path
		if !strings.HasSuffix(fileName, ".sh") {
			var errExt error
			filePath, errExt = exec.LookPath(fileName + ".sh")
			if errExt != nil {
				return usage.Errorf("Error locating '%s'. Paths attempted:\n\t%s\n\t%s", fileName, err, errExt)
			}
		} else {
			return usage.Errorf("Error locating '%s'. Paths attempted:\n\t%s", fileName, err)
		}
	}
	reader, err := os.Open(filePath)
	if err != nil {
		return err
	}
	defer reader.Close()

	name := filepath.Base(fileName)
	name = strings.TrimSuffix(name, filepath.Ext(name))
	if importCache[name] {
		return nil
	}

	parser := syntax.NewParser()
	f, err := parser.Parse(reader, name)
	if err != nil {
		return err
	}

	buf := bytes.NewBufferString("")
	needsInit, err := mutate(buf, f, name)
	if err != nil {
		return err
	}
	printer := syntax.NewPrinter()
	if err := printer.Print(buf, f); err != nil {
		return err
	}
	if needsInit {
		if _, err := buf.WriteString(name + functionPrefixSeparator + "init\n"); err != nil {
			return err
		}
	}

	if err := env.Setenv(outputEnvVar, buf.String()); err != nil {
		return err
	}
	importCache[name] = true
	return nil
}

func mutate(buf *bytes.Buffer, f *syntax.File, name string) (bool, error) {
	functionNames := make(map[string]bool)
	globalVarNames := make(map[string]bool)
	syntax.Walk(f, func(node syntax.Node) bool {
		switch x := node.(type) {
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
		case nil:
			// stop processing after first level
			return false
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
		_, err := buf.WriteString(stringutil.Dedent(`
			` + prefix + `usage() {
				echo 'Usage: ` + name + ` COMMAND' >&2
				echo 'Available commands: '` + allFunctionNames + ` >&2
			}
		`))
		if err != nil {
			return false, err
		}
	}
	if !functionNames[name] {
		_, err := buf.WriteString(stringutil.Dedent(`
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
		`))
		if err != nil {
			return false, err
		}
	}
	if !functionNames["complete"] {
		_, err := buf.WriteString(stringutil.Dedent(`
			` + prefix + `complete() {
				local options=(` + allFunctionNames + `)
				local prev=${COMP_WORDS[COMP_CWORD - 1]}
				if [[ "$prev" != ` + name + ` ]]; then
					return
				fi
				COMPREPLY+=( $(compgen -W "${options[*]}" -- "${COMP_WORDS[COMP_CWORD]}") )
			}
		`))
		if err != nil {
			return false, err
		}
	}
	_, err := buf.WriteString(fmt.Sprintf("complete -F %s %s\n\n", prefix+"complete", name))
	if err != nil {
		return false, err
	}
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

	return functionNames["init"], nil
}

func main() {}
