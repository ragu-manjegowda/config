# Neomutt Configuration Tests

This directory contains comprehensive tests for the Neomutt email client configuration.

## Test Suites

### 1. Config Syntax Tests (`test_config_syntax.sh`)
Validates that all configuration files exist, are readable, and have correct syntax:
- Main config file (`neomuttrc`)
- Key bindings (`bindings.mutt`)
- Styles (`styles.muttrc`)
- Colors (`colors-custom.muttrc`)
- GPG configuration (`gpg.rc`)
- Mailcap file
- Headers file
- Account configurations

### 2. Helper Scripts Tests (`test_scripts.sh`)
Checks that all helper scripts exist, are executable, and have valid syntax:
- `create-alias.sh` - Auto-creates email aliases
- `get-mailboxes.sh` - Retrieves mailbox list
- `mu-search.sh` - Mail search functionality
- `viewmailattachments.py` - View HTML attachments in browser
- `render-calendar-attachment.py` - Render calendar invites
- `mutt-ical.py` - iCalendar handling

### 3. Settings Validation Tests (`test_settings.sh`)
Verifies that critical Neomutt settings are configured correctly:
- Security settings (TLS enforcement)
- Mail checking intervals
- Display settings (wrap width, pager lines)
- Editor configuration (nvim)
- File paths (mailcap, aliases, history)
- Threading and sorting options
- Sidebar configuration

### 4. Mailcap Configuration Tests (`test_mailcap.sh`)
Ensures proper MIME type handling for various file types:
- HTML rendering (w3m)
- PDF viewing (zathura)
- Calendar invites (Python script)
- Image viewing (firefox)
- Audio/Video playback (mpv)
- MS Word documents (nvim)
- Text editing (nvim)

## Running Tests

### Run All Tests
```bash
cd ~/.config/neomutt/tests
./run_all_tests.sh
```

### Run Individual Test Suite
```bash
cd ~/.config/neomutt/tests
./test_config_syntax.sh
./test_scripts.sh
./test_settings.sh
./test_mailcap.sh
```

## CI Integration

Tests automatically run in GitHub Actions when:
- Neomutt configuration files change
- The workflow file itself changes

Tests run on **Arch Linux** (matches your local environment) with each test suite as a separate job for clarity.

## Requirements

- `neomutt` - Email client
- `bash` - Shell for running tests
- `python` - For Python script syntax validation
- `w3m` - HTML rendering (optional for CI)
- `mpv` - Audio/video playback (optional for CI)

## Test Output

Each test prints:
- ✓ PASSED - Test succeeded
- ✗ FAILED - Test failed with details
- ⚠ SKIPPED - Test skipped (usually for optional dependencies in CI)

Exit codes:
- `0` - All tests passed
- `1` - One or more tests failed

