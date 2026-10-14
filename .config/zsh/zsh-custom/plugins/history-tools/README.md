# Shell history tools

One standard-library Python helper powers the Zsh merge and conversion commands.
The plugin replaces `history-sync`; Git-crypt handles checked-in files rather
than this plugin pulling, encrypting, committing, or pushing history.

```sh
merge-curr-zsh-history              # Merge current Zsh history and its .bak files
merge-zsh-history /path/bash_history /path/zsh_history
bash-to-zsh-history /path/bash_history > converted_zsh_history
zsh-to-bash-history /path/zsh_history > converted_bash_history
history-tools merge /path/bash_history /path/zsh_history -o merged_history
```

The two `merge-*` commands include `$ZDOTDIR/.zsh_history` (or `~/.zsh_history`
when ZDOTDIR is unset) and default to `~/zsh_history_merged`. They do not replace
the active history file. Paths with spaces and shell metacharacters are passed
literally. Backup globs may be empty. The merge wrappers have their own `-h/--help`
describing the automatic inputs and default output; help does not invoke Python,
expand backup globs, or read/write history. For standalone format conversion and
advanced options, refer to `history-tools --help`, `history-tools merge --help`,
and `history-tools convert --help`.

Both merge and conversion trim trailing whitespace from each complete command
and deduplicate after trimming, keeping the newest timestamp. Leading whitespace,
internal line spacing, and multiline indentation are preserved. Whitespace-only
commands are omitted. Equal timestamps favor the later input occurrence.
Merge detects extended Zsh and Bash independently for each input file and sorts
chronologically; conversion preserves the relative input order of retained
entries. Bash output retains `#timestamp` markers by default; `--plain` omits them.
Bash has no field for Zsh execution durations.

## Routine-command exclusions

Edit `ignored-commands.txt` in this plugin folder to expand the default list:
`l`, `ls`, `cd`, `mkdir`, `take`, `rm`, `rmdir`, and the example phrase `apt get`.
Use one command-name phrase per line; blank lines and `#` comments are ignored.
Changes apply on the next
merge or conversion without reloading the shell.

Matching is case-sensitive and uses complete tokens, including an explicit
executable path, variable assignments, and common prefixes such as `sudo`, `env`,
`command`, `builtin`, `time`, `noglob`, and `nocorrect`. A phrase such as `apt get`
matches `sudo apt get update` and `sudo -u root apt get update`, but not
`echo "apt get update"` or `apt getter update`. Add `apt-get` separately if you
also want to exclude that distinct executable name.
Thus `ls -la` is omitted, but `lsblk` and `echo ls` remain. Compound
commands, substitutions, multiline entries, and ambiguous shell syntax are kept
conservatively: `cd project && git pull` is not discarded. The tool does not
execute shell code or resolve aliases.

Use a different list or bypass filtering for an invocation:

```sh
merge-zsh-history --exclude-file ~/history-exclusions.txt ~/bash_history
history-tools convert --from zsh --to bash --no-excludes ~/zsh_history_merged
```

Timestamped Bash histories retain multiline boundaries. Plain histories cannot
reliably identify those boundaries or recover timestamps: each physical line is
treated as one command, using the import time or the supplied `--timestamp EPOCH`.
Use `--from bash`, `--from zsh`, or `--from plain` to override ambiguous detection.
Native Zsh Meta-byte escaping, Unicode, and non-UTF-8 command bytes are supported.

The default merged review file is ignored by the dotfiles repository.
The helper writes stdout by default. With `-o/--output`, it reads and validates
all inputs first, then atomically replaces the destination using a private
temporary file. This also permits a destination that is one of the input files;
failed parsing leaves an existing output untouched.

The existing `.config/zsh/zsh_history` Git-crypt rule remains applicable.
Encrypted Git-crypt bytes and legacy GPG-encrypted archives must be decrypted
before use as inputs; the tool does not decrypt them or modify existing archives.

Run the synthetic-fixture tests with:

```sh
python3 -B ~/.config/zsh/zsh-custom/plugins/history-tools/test_history_tools.py
```

To enable timestamps for future Bash history entries, add to `~/.bashrc`:

```bash
export HISTTIMEFORMAT='%F %T '
```

Start a new Bash shell after changing it. Bash writes timestamps as `#<epoch>`
records; the format string controls how `history` displays them. Original
timestamps cannot be recovered for older untimestamped entries.
