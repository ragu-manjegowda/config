# UV System-Wide Virtual Environment Setup

## Installation (New Machine)

### Step 1: Install UV
```bash
# Using Homebrew (recommended)
brew install uv
```

### Step 2: Create System-Wide Venv with UV
```bash
uv venv ~/.local/share/venv
```

### Step 3: Install All Packages from Backup
```bash
# Install everything at once using venv's pip
uv pip install -r ~/.config/pip-backup/requirements.txt
```

### Upgrading Packages
```bash
# Upgrade all packages
uv pip install --upgrade --all
```


## Backup & Restore

### Refer to [pip](.config/pip-backup/README.md)
