# Neomutt Configuration

## Author
Ragu Manjegowda (@ragu-manjegowda)

## Common Commands

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
~/.config/neomutt/accounts/work/mutt_oauth2_outlook.py \
    --verbose \
    --authorize \
    ~/.config/neomutt/accounts/work/TOKEN_FILENAME_outlook
```

**Personal (Gmail):**
```bash
~/.config/neomutt/accounts/personal/mutt_oauth2_raghudarshan.py \
    --verbose \
    --authorize \
    ~/.config/neomutt/accounts/personal/TOKEN_FILENAME_raghudarshan
```

This is needed when:
- Setting up the account for the first time
- The refresh token has expired
- Authentication errors occur

### Sync Emails (mbsync)

Manually sync emails using mbsync:

**Work:**
```bash
mbsync -c ~/.config/neomutt/accounts/work/mbsyncrc_outlook nvidia
```

**Personal:**
```bash
mbsync -c ~/.config/neomutt/accounts/personal/mbsyncrc_raghudarshan raghudarshan
```

### List Available Mailboxes

To list all available mailboxes from the IMAP server:

**Work:**
```bash
mbsync -Vl -c ~/.config/neomutt/accounts/work/mbsyncrc_outlook nvidia
```

**Personal:**
```bash
mbsync -Vl -c ~/.config/neomutt/accounts/personal/mbsyncrc_raghudarshan raghudarshan
```
