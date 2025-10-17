# UV Tools Backup & Management

**Backup Date:** 2025-10-16  
**Migration:** From pip/venv to UV modern workflow

---

## Current Installation

### Installed Tools (10 packages):

1. **jupyterlab** - Jupyter notebooks and lab interface
2. **spotdl** - Spotify music downloader
3. **subliminal** - Subtitle downloader
4. **python-lsp-server** - Python Language Server for neovim/IDEs (with mypy, black, ruff)
5. **mutt-language-server** - Mutt email client LSP
6. **tmux-language-server** - Tmux configuration LSP
7. **pynvim** - Neovim Python support
8. **nbdev** - Jupyter notebook development tools
9. **img2pdf** - Convert images to PDF
10. **pdfminer.six** - Extract text from PDFs

**Full list:** See `installed-tools.txt`

---

## Maintenance Commands

### List Installed Tools
```bash
# List all installed tools
uv tool list

# List tools with package names only
uv tool list | grep -E "^[a-z]"
```

### Upgrade All Tools
```bash
# Upgrade all tools to latest versions
uv tool upgrade --all
```

### Upgrade Specific Tool
```bash
# Upgrade a single tool
uv tool upgrade jupyterlab
uv tool upgrade spotdl
uv tool upgrade python-lsp-server
```

### Check for Updates (without installing)
```bash
# List outdated tools
uv tool list --outdated
```

---

## Installation Commands

### Install UV on New Machine
```bash
# Using Homebrew (recommended)
brew install uv

# Or using official installer
curl -LsSf https://astral.sh/uv/install.sh | sh

# Or on Arch Linux
sudo pacman -S uv
```

### Reinstall All Tools (from this backup)
```bash
# One-liner: Install all tools from tools-list.txt
xargs -n1 uv tool install < ~/.config/uv-backup/tools-list.txt

# Or if you're in the backup directory:
cd ~/.config/uv-backup
xargs -n1 uv tool install < tools-list.txt
```

**Alternative: Install individually**
```bash
# If you prefer to install one at a time
uv tool install jupyterlab
uv tool install spotdl
uv tool install subliminal
uv tool install 'python-lsp-server[all]'
uv tool install mutt-language-server
uv tool install tmux-language-server
uv tool install pynvim
uv tool install nbdev
uv tool install img2pdf
uv tool install pdfminer.six
```

### Add New Tools
```bash
# Install a new global tool
uv tool install <package-name>

# Examples:
uv tool install ruff      # Fast Python linter
uv tool install black     # Code formatter
uv tool install httpie    # HTTP client
uv tool install yt-dlp    # YouTube downloader
```

### Remove Tools
```bash
# Uninstall a tool
uv tool uninstall <tool-name>

# Example:
uv tool uninstall nbdev
```

---

## Verifying Tools Work

### Test Executables
```bash
# Test that tools are available
jupyter-lab --version
spotdl --version
subliminal --version
pylsp --version
mutt-language-server --version
tmux-language-server --version
pynvim-python --version
img2pdf --version
pdf2txt.py --version
```

### Check Tool Locations
```bash
# See where tools are installed
which jupyter-lab
which spotdl
which pylsp

# Should show: ~/.local/bin/<tool>
```

---

## Tool-Specific Notes

### JupyterLab
```bash
# Start Jupyter Lab
jupyter-lab

# With specific directory
jupyter-lab ~/notebooks

# Install extensions (if needed)
jupyter-labextension list
```

### Python LSP Server (for Neovim)
```bash
# Test LSP server
pylsp --help

# Included plugins:
# - mypy (type checking)
# - black (formatting)
# - ruff (linting)
# - autopep8, flake8, pylint, yapf, etc.

# No separate installation of plugins needed!
```

### SpotDL
```bash
# Download a song
spotdl "https://open.spotify.com/track/..."

# Download playlist
spotdl "https://open.spotify.com/playlist/..."
```

### Subliminal
```bash
# Download subtitles for a video
subliminal download -l en video.mp4

# Search for subtitles
subliminal list-subtitles video.mp4
```

---

## Migration Notes

### What Changed
- **Old:** Single venv at `~/.local/share/venv/` (backed up to `~/.local/share/venv.backup.20251016`)
- **New:** Each tool has isolated environment in `~/.local/share/uv/tools/`
- **PATH:** `~/.local/bin/` contains symlinks to all tool executables
- **No activation:** Tools are always available globally

### Old Requirements
Original pip requirements saved in: `~/.config/pip-backup/requirements.txt`

**CLI Tools** (installed with `uv tool install`): 10 packages  
**Libraries** (for project use): 21 packages (add to projects as needed)

---

## Troubleshooting

### Tool not found after install
```bash
# Check if tool is installed
uv tool list | grep <tool-name>

# Check PATH
echo $PATH | grep ".local/bin"

# Reload shell
source ~/.profile
# or logout/login
```

### Reinstall broken tool
```bash
# Remove and reinstall
uv tool uninstall <tool-name>
uv tool install <tool-name>
```

### UV not found
```bash
# Install UV (if missing)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Or with Arch pacman
sudo pacman -S uv
```

---

## Backup Strategy

### Manual Backup
```bash
# Save current tool list (reference format)
uv tool list > ~/.config/uv-backup/installed-tools-$(date +%Y%m%d).txt

# Update tools-list.txt (for installation)
# Edit ~/.config/uv-backup/tools-list.txt
# Add one package name per line (no versions)

# Example:
# jupyterlab
# spotdl
# new-tool-name

# Update README date
# Edit this file and update "Backup Date"
```

### Restore from Backup
```bash
# On new machine: Install all tools at once
xargs -n1 uv tool install < ~/.config/uv-backup/tools-list.txt
```

---

## UV Documentation

- **Official docs:** https://docs.astral.sh/uv/
- **Tool management:** https://docs.astral.sh/uv/guides/tools/
- **GitHub:** https://github.com/astral-sh/uv

---

## Quick Reference

```bash
# Install all tools from backup
xargs -n1 uv tool install < ~/.config/uv-backup/tools-list.txt

# List tools
uv tool list

# Upgrade all
uv tool upgrade --all

# Upgrade one
uv tool upgrade <tool>

# Install new
uv tool install <package>

# Remove tool
uv tool uninstall <tool>

# Save reference backup
uv tool list > ~/.config/uv-backup/installed-tools-$(date +%Y%m%d).txt
```

