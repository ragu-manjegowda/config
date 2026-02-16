# Arch Linux Bootstrap

Automated system setup for a fresh Arch Linux install.

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/ragu-manjegowda/config/refs/heads/master/.config/scripts/bootstrap/init.sh | bash
```

## Usage

```bash
# Full setup
~/.config/scripts/bootstrap/bootstrap.sh

# Run a specific step
~/.config/scripts/bootstrap/bootstrap.sh --only 2

# Resume from a step
~/.config/scripts/bootstrap/bootstrap.sh --from 4
```

## Steps

| Step | Name |
|------|------|
| 0 | Dotfiles |
| 1 | Packages |
| 2 | Security |
| 3 | System |
| 4 | Hardware |
| 5 | Services |
| 6 | Desktop |
| 7 | Apps |
