# Neomutt Configuration

<!--toc:start-->
- [Neomutt Configuration](#neomutt-configuration)
  - [Author](#author)
  - [Directory Structure](#directory-structure)
  - [Account Overview](#account-overview)
    - [Online Mode (i1, i3)](#online-mode-i1-i3)
    - [Offline Mode (i2, i4)](#offline-mode-i2-i4)
  - [Common Commands](#common-commands)
    - [Initialize Paths (New Machine)](#initialize-paths-new-machine)
    - [Update Mailboxes](#update-mailboxes)
    - [OAuth2 Authorization](#oauth2-authorization)
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
│   ├── mutt-ical.py             # Calendar invite handler
│   ├── render-calendar-attachment.py
│   ├── sync-notmuch-flags.sh    # Sync maildir flags ↔ notmuch tags
│   └── viewmailattachments.py   # HTML email viewer
│
├── credentials/                 # Encrypted credentials & tokens
│   ├── pass_outlook.gpg         # Work account credentials
│   ├── pass_gmail-personal.gpg  # Personal account credentials
│   ├── token_outlook            # Work OAuth2 token (GPG encrypted)
│   └── token_gmail-personal     # Personal OAuth2 token (GPG encrypted)
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

### OAuth2 Authorization

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
