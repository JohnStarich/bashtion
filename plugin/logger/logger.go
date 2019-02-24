package logger

import (
	"errors"
	"fmt"
	"os"
	"strings"

	"github.com/johnstarich/bashtion/plugin/command"
	"github.com/johnstarich/bashtion/plugin/usage"
	"github.com/johnstarich/goenable/env"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

var (
	errUsage = usage.Errorf(Usage())
)

// Logger is a simple command-line logger
type Logger struct {
	command.Command
	logger   *zap.Logger
	logLevel zap.AtomicLevel
}

// Usage returns the full set of documentation for this plugin
func Usage() string {
	return strings.TrimSpace(`
Usage: logger LEVEL ARGS [ARGS ...]
Levels: all, trace, debug, info, warn, error, fatal, off

logger set level LEVEL
	Changes the log level to LEVEL
`)
}

// Usage returns the full set of documentation for this plugin
func (l *Logger) Usage() string {
	return Usage()
}

// Load runs any set up required by this plugin
func (l *Logger) Load() error {
	logLevelEnv := env.Getenv("LOG_LEVEL")
	initialLevel := zap.InfoLevel
	if parsedLevel, err := levelFromString(logLevelEnv); err == nil {
		initialLevel = parsedLevel
	}
	l.logLevel = zap.NewAtomicLevelAt(initialLevel)

	encoderCfg := zap.NewDevelopmentEncoderConfig()
	encoderCfg.TimeKey = ""
	encoderCfg.EncodeLevel = zapcore.CapitalColorLevelEncoder

	l.logger = zap.New(zapcore.NewCore(
		zapcore.NewConsoleEncoder(encoderCfg),
		zapcore.Lock(os.Stderr),
		l.logLevel,
	))
	return nil
}

// Unload runs any tear down required by this plugin
func (l *Logger) Unload() {
	l.logger.Sync()
}

// Run executes this plugin with the given arguments
func (l *Logger) Run(args []string) error {
	if len(args) < 1 {
		return errUsage
	}
	if args[0] == "level" {
		if len(args) == 1 {
			fmt.Println(l.logLevel.String())
			return nil
		}
		level, err := levelFromString(args[1])
		if err != nil {
			return err
		}
		l.logLevel.SetLevel(level)
		return nil
	}

	if len(args) < 2 {
		return errUsage
	}
	level, err := levelFromString(args[0])
	if err != nil {
		return err
	}
	message := strings.Join(args[1:], " ")
	if check := l.logger.Check(level, message); check != nil {
		check.Write()
	}
	return nil
}

func levelFromString(level string) (zapcore.Level, error) {
	switch strings.ToLower(level) {
	case "debug":
		return zapcore.DebugLevel, nil
	case "info":
		return zapcore.InfoLevel, nil
	case "warn":
		return zapcore.WarnLevel, nil
	case "error":
		return zapcore.ErrorLevel, nil
	case "fatal":
		return zapcore.FatalLevel, nil
	default:
		return zapcore.FatalLevel, errors.New("Invalid logging level: " + level)
	}
}
