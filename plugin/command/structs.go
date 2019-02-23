package command

// Command is a tiny plugin inside bashtion. This behaves like a subcommand.
type Command interface {
	Usage() string
	Load() error
	Unload()
	Run([]string) error
}
