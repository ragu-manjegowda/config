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
│   ├── create-alias.sh          # Auto-create aliases from mail
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
├── accounts/                    # Per-account configuration
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
        ├── aliases              # Auto-generated aliases
        └── history              # Command history
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
(`~/.config/awesome/utilities/outlook-calendar`) calls `oauth2.py` with a
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
~/.config/awesome/utilities/outlook-calendar --days 2
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

Manually sync emails using mbsync:

**Work:**
```bash
mbsync -c ~/.config/neomutt/accounts/work/mbsyncrc outlook
```

**Personal:**
```bash
mbsync -c ~/.config/neomutt/accounts/personal/mbsyncrc gmail-personal
```

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
