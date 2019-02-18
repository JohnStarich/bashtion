package main

import (
	"errors"
	"os"
	"strings"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

var (
	logger   *zap.Logger
	logLevel zap.AtomicLevel
	errUsage = errors.New(Usage())
)

// Usage returns the full set of documentation for this plugin
func Usage() string {
	return strings.TrimSpace(`
Usage: logger LEVEL ARGS [ARGS ...]
Levels: all, trace, debug, info, warn, error, fatal, off

logger set level LEVEL
	Changes the log level to LEVEL
`)
}

// Load runs any set up required by this plugin
func Load() error {
	logLevel = zap.NewAtomicLevelAt(zap.InfoLevel)

	encoderCfg := zap.NewDevelopmentEncoderConfig()
	encoderCfg.TimeKey = ""
	encoderCfg.EncodeLevel = zapcore.CapitalColorLevelEncoder

	logger = zap.New(zapcore.NewCore(
		zapcore.NewConsoleEncoder(encoderCfg),
		zapcore.Lock(os.Stderr),
		logLevel,
	))
	return nil
}

// Unload runs any tear down required by this plugin
func Unload() {
	logger.Sync()
}

// Run executes this plugin with the given arguments
func Run(args []string) (int, error) {
	if len(args) < 2 {
		return 2, errUsage
	}
	if args[0] == "set" {
		if args[1] != "level" || len(args) < 3 {
			return 2, errUsage
		}
		level, err := levelFromString(args[2])
		if err != nil {
			return 2, err
		}
		logLevel.SetLevel(level)
		return 0, nil
	}
	level, err := levelFromString(args[0])
	if err != nil {
		return 2, err
	}
	message := strings.Join(args[1:], " ")
	if check := logger.Check(level, message); check != nil {
		check.Write()
	}
	return 0, nil
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
func main() {}
