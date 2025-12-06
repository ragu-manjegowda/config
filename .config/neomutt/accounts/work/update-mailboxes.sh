#!/usr/bin/env bash
###############################################################################
## Author       : Ragu Manjegowda
## Github       : @ragu-manjegowda
## Description  : Update neomutt mailboxes from mbsync for both outlook configs
###############################################################################

set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/neomutt/accounts/work"
CONFIG_FILES=("$CONFIG_DIR/outlook" "$CONFIG_DIR/outlook-offline")
MBSYNC_CONFIG="$CONFIG_DIR/mbsyncrc_outlook"
ACCOUNT="nvidia"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Check if mbsync config exists
if [[ ! -f "$MBSYNC_CONFIG" ]]; then
    log_error "mbsync config not found: $MBSYNC_CONFIG"
    exit 1
fi

log_info "Fetching mailbox list from mbsync..."

# Get mailboxes from mbsync (filter out status messages)
MAILBOXES=$(mbsync -Vl -c "$MBSYNC_CONFIG" "$ACCOUNT" 2>/dev/null | \
    grep -v "^Reading\|^Channel\|^Opening\|^Resolving\|^Connecting\|^Connection\|^Logging\|^Authenticating" | \
    sort)

if [[ -z "$MAILBOXES" ]]; then
    log_error "No mailboxes returned from mbsync"
    exit 1
fi

log_info "Found $(echo "$MAILBOXES" | wc -l) mailboxes from mbsync"

# Function to update a single config file
update_config_file() {
    local config_file="$1"
    
    log_section "Processing: $(basename "$config_file")"
    
    # Check if config file exists
    if [[ ! -f "$config_file" ]]; then
        log_warn "Config file not found: $config_file - skipping"
        return 1
    fi

    # Extract named-mailboxes entries (these have icons and should be preserved)
    # Format: named-mailboxes "   Icon Name" =FolderName or ="Folder Name"
    NAMED_FOLDERS=$(grep "^named-mailboxes" "$config_file" | \
        sed 's/.*="\?\([^"]*\)"\?$/\1/')

    log_info "Named mailboxes (excluded from mailboxes list):"
    echo "$NAMED_FOLDERS" | while read -r folder; do
        [[ -n "$folder" ]] && echo "  - $folder"
    done

    # Filter out named mailboxes from the mbsync list
    FILTERED_MAILBOXES=$(echo "$MAILBOXES" | while read -r mailbox; do
        skip=false
        while IFS= read -r named; do
            # Case-insensitive comparison
            if [[ -n "$named" ]] && [[ "${mailbox,,}" == "${named,,}" ]]; then
                skip=true
                break
            fi
        done <<< "$NAMED_FOLDERS"
        
        if [[ "$skip" == "false" ]]; then
            echo "$mailbox"
        fi
    done)

    log_info "Filtered mailboxes count: $(echo "$FILTERED_MAILBOXES" | wc -l)"

    # Create backup
    BACKUP_FILE="${config_file}.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$config_file" "$BACKUP_FILE"
    log_info "Created backup: $BACKUP_FILE"

    # Create a temporary file
    TEMP_FILE=$(mktemp)

    # State machine to process the file
    in_mailboxes_section=false
    mailboxes_written=false

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Check if we're entering the mailboxes section
        if [[ "$line" =~ ^mailboxes[[:space:]]*\\ ]]; then
            in_mailboxes_section=true
            if [[ "$mailboxes_written" == "false" ]]; then
                # Generate new mailboxes section
                echo 'mailboxes \' >> "$TEMP_FILE"
                
                # Get count for determining last line
                local count=$(echo "$FILTERED_MAILBOXES" | grep -c .)
                local current=0
                
                echo "$FILTERED_MAILBOXES" | while read -r mailbox; do
                    if [[ -n "$mailbox" ]]; then
                        current=$((current + 1))
                        escaped_mailbox=$(echo "$mailbox" | sed 's/"/\\"/g')
                        if [[ $current -lt $count ]]; then
                            echo "    \"=$escaped_mailbox\" \\" >> "$TEMP_FILE"
                        else
                            echo "    \"=$escaped_mailbox\"" >> "$TEMP_FILE"
                        fi
                    fi
                done
                
                mailboxes_written=true
            fi
            continue
        fi
        
        # If we're in mailboxes section, skip lines until we find a non-continuation line
        if [[ "$in_mailboxes_section" == "true" ]]; then
            # Check if line continues (is a quoted mailbox entry)
            if [[ "$line" =~ ^[[:space:]]*\"= ]]; then
                continue
            else
                # End of mailboxes section
                in_mailboxes_section=false
                # Don't add extra blank line - the next line from file will handle spacing
            fi
        fi
        
        # Write the line if we're not in the mailboxes section
        if [[ "$in_mailboxes_section" == "false" ]]; then
            echo "$line" >> "$TEMP_FILE"
        fi
    done < "$config_file"

    # Move temp file to config
    mv "$TEMP_FILE" "$config_file"

    log_info "Updated: $config_file"

    # Show diff
    if command -v diff &> /dev/null; then
        log_info "Changes:"
        diff --color=auto "$BACKUP_FILE" "$config_file" || true
    fi
}

# Process all config files
for config_file in "${CONFIG_FILES[@]}"; do
    update_config_file "$config_file"
done

echo ""
log_info "All config files updated successfully!"
