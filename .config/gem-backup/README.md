# User Ruby tools

Run `topgrade --gems` to install or upgrade the tools in `packages.in` for
the active Ruby. A normal `topgrade` run includes this step. RubyGems keeps
the gems in its version-specific user directory and writes their commands to
`~/.local/bin`, so terminal sessions don't need a new PATH after a Ruby upgrade.

Pacman owns Ruby and RubyGems on Arch. After a Ruby ABI change, run
`topgrade --gems` again to install the tools for that Ruby. Project dependencies
such as Jekyll belong in the project's Gemfile, not this list.
