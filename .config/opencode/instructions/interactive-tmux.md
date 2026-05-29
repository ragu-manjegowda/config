# Interactive Command Policy

When running any command, terminal app, or workflow that may require user interaction, use the existing tmux session named `ragu`.

This includes commands that may prompt for credentials, passphrases, confirmations, or TTY input, such as GPG authentication for neomutt, `sudo` prompts, interactive installers, terminal UIs, editors, pagers, REPLs, and any long-running process that the user may need to inspect or control.

Prefer the tmux tooling for these cases and target the `ragu` session explicitly. Do not start a separate tmux session with another name unless the user explicitly asks for it.
