# Neomutt Configuration

<!--toc:start-->
- [Neomutt Configuration](#neomutt-configuration)
  - [Directory Structure](#directory-structure)
  - [Account Overview](#account-overview)
    - [Online Mode (i1, i3)](#online-mode-i1-i3)
    - [Offline Mode (i2, i4)](#offline-mode-i2-i4)
  - [Calendar Features](#calendar-features)
    - [Inline Calendar Rendering](#inline-calendar-rendering)
    - [Accept/Decline Calendar Invites](#acceptdecline-calendar-invites)
    - [Outlook Calendar via Microsoft Graph API](#outlook-calendar-via-microsoft-graph-api)
  - [OAuth2](#oauth2)
    - [Token Storage](#token-storage)
    - [Authorization](#authorization)
    - [Graph API Token (Outlook Calendar)](#graph-api-token-outlook-calendar)
  - [Common Commands](#common-commands)
    - [Initialize Paths (New Machine)](#initialize-paths-new-machine)
    - [Update Mailboxes](#update-mailboxes)
    - [Sync Emails (mbsync)](#sync-emails-mbsync)
    - [List Available Mailboxes](#list-available-mailboxes)
    - [Setup Offline Mode (New Machine)](#setup-offline-mode-new-machine)
<!--toc:end-->

## Directory Structure

```sh
~/.config/neomutt/
├── neomuttrc                    # Main entry point
├── README.md                    # This file
│
├── config/                      # Mutt configuration files
│   ├── bindings.mutt            # Keybindings
│   ├── colors.muttrc            # Color scheme
│   ├── gpg.rc                   # GPG integration
│   ├── headers                  # Custom headers
│   ├── mailcap                  # MIME handlers
│   └── styles.muttrc            # Status bar, index format
│
├── scripts/                     # Helper scripts
│   ├── create-alias.py          # Auto-create aliases from mail
│   ├── query-aliases.py         # Fuzzy address completion for Tab
│   ├── fzf-notmuch-search.sh    # Fuzzy search with fzf
│   ├── get-mailboxes.sh         # List mailboxes from mbsync
│   ├── mu-search.sh             # mu mail search
│   ├── mutt-ical.py             # Accept/decline calendar invites
│   ├── render-calendar-attachment.py  # Inline iCal (.ics) renderer
│   ├── setup-paths.sh           # Initialize dirs on new machine
│   └── sync-notmuch-flags.sh    # Sync maildir flags ↔ notmuch tags
│
├── credentials/                 # Encrypted credentials & tokens
│   ├── pass_outlook.gpg         # Work account credentials
│   ├── pass_gmail-personal.gpg  # Personal account credentials
│   ├── token_outlook            # Work OAuth2 token (IMAP/SMTP)
│   ├── token_outlook_graph      # Work OAuth2 token (Microsoft Graph API)
│   └── token_gmail-personal     # Personal OAuth2 token
│
├── accounts/                    # Encrypted account data and configuration
│   ├── aliases                  # Shared From/To aliases (git-crypt)
│   ├── alias-blacklist          # Email substring exclusions (git-crypt)
│   ├── work/
│   │   ├── config               # Online mode (IMAP direct)
│   │   ├── config-offline       # Offline mode (Maildir)
│   │   ├── mbsyncrc             # mbsync configuration
│   │   ├── msmtprc              # SMTP configuration
│   │   ├── oauth2.py            # OAuth2 refresh script
│   │   ├── setup-offline.sh     # Setup script for new machines
│   │   └── update-mailboxes.sh  # Sync folder list from IMAP
│   └── personal/
│       └── (same structure)
│
├── assets/                      # Static assets
│   └── neomutt.svg              # Icon for notifications
│
├── tests/                       # Test suite
│
└── .gitignored/                 # Runtime data (not tracked)
    ├── cache/                   # Header and body caches
    ├── maildir/                 # Email storage (Maildir format)
    │   ├── outlook/             # Work account emails
    │   └── gmail-personal/      # Personal account emails
    └── data/
        └── history              # Command history
```

Opening a message in the pager adds new From and To addresses to the shared
alias file. Existing aliases, account identities, and automated senders are
skipped. NeoMutt loads aliases at startup, so restart or re-source the file
to use newly saved entries in recipient completion.
During recipient entry, Ctrl+T opens NeoMutt's native alias menu, including
when the field is empty. After typing part of a name, key, or email, Tab uses
fzf to rank matches and NeoMutt's native query menu to select multiple matches.

Edit `accounts/alias-blacklist` to exclude contacts from automatic alias creation.
Put one substring per line: matching is case-insensitive against the email
address only, not the display name. Entries are literal text, not regexes or
wildcards; blank lines and lines starting with `#` are ignored. The file starts
with the existing service exclusions and `exchange.nvidia.com`. It is reread
each time the display filter runs, so edits need no NeoMutt restart.
Common no-reply variants in email local parts are also skipped automatically.
This affects new aliases; it does not remove existing entries.

The `.gitattributes` rule for `.config/neomutt/accounts/**` encrypts the blacklist
with Git-crypt, just like `accounts/aliases`. A locked blacklist suspends alias
creation while message display continues unchanged. A missing blacklist adds
no custom exclusions.

## Browser message view

`,of` opens the complete current message in Firefox from the index, pager, or
attachment menu. It shows the original Subject, From, To, Cc, Reply-To, and Date
headers, resolves MIME `cid:`/Content-Location images, and offers attachment
downloads. HTTPS images remain normal browser image requests.

The viewer creates a separate private temporary directory per message instead
of overwriting `/tmp/mutt-attach`. HTML and attachment files are private, and
the message body is sandboxed with scripts and forms disabled. MIME parts are
kept intact while piping, and the previous `pipe_decode` setting is restored.

To load updated bindings in an already running session:

```text
:source ~/.config/neomutt/config/bindings.mutt
```

## Account Overview

| Account | Key | Receiving | Sending | Searching | Auth |
|---------|-----|-----------|---------|-----------|------|
| outlook | i1 | IMAP direct to Office365 | SMTP direct | IMAP server-side | OAuth2 |
| outlook-offline | i2 | IMAP via mbsync to Maildir | SMTP via msmtp | notmuch (local) | OAuth2 |
| gmail-personal | i3 | IMAP direct to Gmail | SMTP direct | IMAP server-side | OAuth2 |
| gmail-personal-offline | i4 | IMAP via mbsync to Maildir | SMTP via msmtp | notmuch (local) | OAuth2 |

### Online Mode (i1, i3)

```mermaid
┌─────────────┐     IMAP      ┌──────────────┐
│   Neomutt   │◄─────────────►│ Mail Server  │
│             │     SMTP      │ (O365/Gmail) │
└─────────────┘──────────────►└──────────────┘
```

- Always up-to-date, no local storage needed
- Requires network, slower search (single folder only)

### Offline Mode (i2, i4)

```mermaid
┌─────────────┐              ┌─────────────┐     IMAP      ┌──────────────┐
│   Neomutt   │◄────────────►│   Maildir   │◄─────────────►│ Mail Server  │
│             │              │   (local)   │    mbsync     │ (O365/Gmail) │
└─────────────┘              └─────────────┘               └──────────────┘
       │                           │
       │                           │
       ▼                           ▼
┌─────────────┐              ┌─────────────┐
│   msmtp     │──── SMTP ───►│ Mail Server │
└─────────────┘              └─────────────┘
       │
       ▼
┌─────────────┐
│  notmuch    │ (search index)
└─────────────┘
```

- Fast local access, cross-folder search with folder names, works offline (read)
- Requires storage, needs periodic sync

## Calendar Features

### Inline Calendar Rendering

Calendar invites (`text/calendar`, `application/ics`) are automatically rendered
inline in the pager using `render-calendar-attachment.py`. This displays event
details (title, date/time, location, organizer, invitees) directly in the email
body without needing to save or open the attachment externally.

Configured via `mailcap` and `auto_view` in `neomuttrc`:
```
auto_view text/calendar
auto_view application/ics
alternative_order text/calendar application/ics text/html text/plain ...
```

### Accept/Decline Calendar Invites

From the attachment view, press `,ai` to interactively accept, decline, or
tentatively accept a calendar invitation. This uses `mutt-ical.py` which:
- Parses the `.ics` attachment
- Displays event details (organizer, title, attendees, description)
- Prompts for response (accept/decline/tentative)
- Sends the iCal reply back to the organizer via neomutt

### Outlook Calendar via Microsoft Graph API

The neomutt OAuth2 infrastructure is reused by the AwesomeWM calendar widget to
fetch Outlook calendar events via the Microsoft Graph API. A dedicated script
(`~/.config/awesome/utilities/network/outlook-calendar`) calls `oauth2.py` with a
separate Graph API token to query `graph.microsoft.com/v1.0/me/calendarview`.

This enables a desktop calendar events widget in the AwesomeWM info-center panel
that shows upcoming events with:
- Subject, time range, location, organizer
- Concurrent event grouping with expand/collapse
- Auto-scroll to current/next event
- Today/tomorrow/day-of-week labels
- Configurable event window (default: 2 days)

The widget is configured in `~/.config/awesome/configuration/config.lua`:
```lua
calendar_events = {
    script = config_dir .. 'utilities/outlook-calendar',
    window_days = 2,
    max_items = 0,
    show_cancelled = false,
}
```

## OAuth2

### Token Storage

OAuth2 tokens are stored as **plain JSON** files (with `0600` permissions) in
`credentials/`. The `oauth2.py` script supports both Google and Microsoft
registrations with three authorization flows: `authcode`, `localhostauthcode`,
and `devicecode`.

Tokens are automatically refreshed when expired. Encryption via GPG is
optionally supported by setting `ENCRYPTION_PIPE`/`DECRYPTION_PIPE` in the
script.

### Authorization

Run all authentication flows interactively, with the option to skip each one:

```bash
~/.config/neomutt/scripts/authenticate.sh
```

Or authorize individual accounts directly:

To authorize or re-authorize OAuth2 tokens:

**Work (Outlook):**
```bash
~/.config/neomutt/accounts/work/oauth2.py \
    --verbose \
    --authorize \
    ~/.config/neomutt/credentials/token_outlook
```

**Personal (Gmail):**
```bash
~/.config/neomutt/accounts/personal/oauth2.py \
    --verbose \
    --authorize \
    ~/.config/neomutt/credentials/token_gmail-personal
```

This is needed when:
- Setting up the account for the first time
- The refresh token has expired
- Authentication errors occur

### Graph API Token (Outlook Calendar)

A separate token is used for Microsoft Graph API access (calendar events).
This token requires the `Calendars.Read` scope:

```bash
~/.config/neomutt/accounts/work/oauth2.py \
    --verbose \
    --authorize \
    ~/.config/neomutt/credentials/token_outlook_graph
```

Test fetching events:
```bash
~/.config/awesome/utilities/network/outlook-calendar --days 2
```

## Common Commands

### Initialize Paths (New Machine)

Create required folders for maildir, cache, data, and logs:

```bash
~/.config/neomutt/scripts/setup-paths.sh
```

Logs are written to:
- `~/.local/state/neomutt/`

### Update Mailboxes

Sync the mailbox list from the IMAP server and update config files.

**Work (Outlook):**
```bash
~/.config/neomutt/accounts/work/update-mailboxes.sh
```

**Personal (Gmail):**
```bash
~/.config/neomutt/accounts/personal/update-mailboxes.sh
```

These scripts:
- Fetch current mailbox list from mbsync
- Preserve named-mailboxes with icons (Inbox, Drafts, Sent Items, Deleted Items)
- Update the `mailboxes` section in config files
- Create timestamped backups before modifying
- Show diff of changes made

### Sync Emails (mbsync)

Manually sync through the same locked worker used by background notifications.
This prevents overlapping `mbsync` processes and shared-log corruption, then
updates the selected account's Notmuch index on success:

**Work:**
```bash
FULL_SYNC=1 MAIL_SYNC_ACCOUNT=outlook ~/.config/imapnotify/notify.sh
```

**Personal:**
```bash
FULL_SYNC=1 MAIL_SYNC_ACCOUNT=gmail-personal ~/.config/imapnotify/notify.sh
```

Omit `MAIL_SYNC_ACCOUNT` to sync both accounts. Manual requests wait for an
existing worker; background callbacks coalesce instead of competing. The
personal offline `o` binding saves mailbox flags before launching a Gmail-only
full sync and reports failures as well as successes. After changing the macro,
reload the account configuration in an already running NeoMutt session.

Each manual run retains private per-account logs and a `status` file under
`${XDG_STATE_HOME:-$HOME/.local/state}/neomutt/manual-sync-*/`. The status records
the account scope, overall exit code, and failing stage (mbsync, indexing,
summary fetch, or lock timeout). `failed_exit_codes` preserves the underlying
command exit codes, and each failed stage logs its actual code. Mbsync output
is line-buffered so new output appears while the command is still running.
Driver tracing is off by default; enable metadata-only tracing for a diagnostic
manual run with `MAIL_SYNC_DEBUG=1 FULL_SYNC=1 ~/.config/imapnotify/notify.sh`.

`manual-sync-last` points to the latest started
attempt immediately, with log files ready even while it waits for the sync
lock. Its `status` file appears when that attempt finishes; background sync
cannot overwrite these diagnostics. Follow concise progress for both accounts,
including lock waits, synchronization, indexing, and the final result, with:

```bash
tail -F "${XDG_STATE_HOME:-$HOME/.local/state}/neomutt/manual-sync.log"
```

`manual-sync.log` is a direct file symlink, so `tail -F` notices replacements
when a new run starts. Following files through the changing directory symlink
`manual-sync-last` is unreliable with Linux inotify and can keep showing an
older run.

Inside each run, `mbsync-outlook.log` and `mbsync-gmail-personal.log` contain
account synchronization output. `notmuch-outlook.log` and
`notmuch-gmail-personal.log` contain the corresponding indexing output.
`fetch-outlook.log` contains the work unread-mail summary. Only logs for the
selected accounts are created. A stage's output file may be empty until that
stage starts; `sync.log` always shows current progress.

Root-level `mbsync-*.log` and `fetch-outlook.log` are separate rolling logs from
background notifications. Root-level `msmtp-*.log` records outgoing mail and
is independent of synchronization. The old root-level `notmuch-*.log` files
were produced by earlier macros; current manual indexing logs live inside
their run directory.

Only the latest three completed manual runs are retained; in-progress runs
and unrelated diagnostic directories are left alone. `manual-sync-last` and
`manual-sync.log` are shortcuts to the latest run, not extra retained runs.

### List Available Mailboxes

To list all available mailboxes from the IMAP server:

**Work:**
```bash
mbsync -Vl -c ~/.config/neomutt/accounts/work/mbsyncrc outlook
```

**Personal:**
```bash
mbsync -Vl -c ~/.config/neomutt/accounts/personal/mbsyncrc gmail-personal
```

### Setup Offline Mode (New Machine)

Run these scripts to initialize offline mode (creates maildir, notmuch config, initial sync):

**Work (Outlook):**
```bash
~/.config/neomutt/accounts/work/setup-offline.sh
```

**Personal (Gmail):**
```bash
~/.config/neomutt/accounts/personal/setup-offline.sh
```
