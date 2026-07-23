# Tmux Command Policy

Always create a new window in the existing tmux session named `ragu` before sending or running any shell command, terminal application, or command-based workflow. Send the command to that new window and do not reuse an existing window.

This rule applies to every command, including non-interactive and short-lived commands. It also applies to commands that may prompt for credentials, passphrases, confirmations, or TTY input, such as GPG authentication for neomutt, `sudo` prompts, interactive installers, terminal UIs, editors, pagers, REPLs, and long-running processes that the user may need to inspect or control.

Target the `ragu` session explicitly for every new window. Do not start a separate tmux session or use another session unless the user explicitly asks for it.
