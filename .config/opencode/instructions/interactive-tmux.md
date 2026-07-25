# Interactive Tmux Policy

Use tmux only when a command requires user interaction. Run non-interactive commands normally without creating a tmux window, even when they are long-running.

Interactive commands include prompts for credentials, passphrases, confirmations, device codes, callback URLs, or other TTY input, as well as terminal applications the user must directly control. Examples include GPG authentication for neomutt, `sudo` prompts, interactive installers, terminal UIs, editors, pagers, and REPLs.

For interactive commands, create a new window in the existing tmux session named `ragu` and target that session explicitly. Do not start another tmux session or use an existing window unless the user explicitly asks.

Track every tmux window created by OpenCode. Close it when the interaction finishes, fails, is cancelled, or is no longer needed. Never close a window that OpenCode did not create.
