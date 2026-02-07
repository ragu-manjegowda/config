#!/bin/bash

###############################################################################
## Reference         : https://github.com/jpmenil/dotfiles/blob/master/.config/neomutt/aliases.sh
## Modified by       : Ragu Manjegowda
## Github            : @ragu-manjegowda
###############################################################################

ALIASFILE="$HOME/.config/neomutt/.gitignored/data/aliases"
MESSAGE=$(cat)

NEWALIAS=$(printf "%s" "$MESSAGE" | python - <<'PY'
import re
import sys
from email.utils import parseaddr

message = sys.stdin.read()
from_line = ""
for line in message.splitlines():
    if line.startswith("From: "):
        from_line = line[6:]
        break

if not from_line:
    sys.exit(0)

# Remove links index (like [6]) added by w3m in mailcap
from_line = re.sub(r"\[[0-9]+\]", "", from_line)

name, email = parseaddr(from_line)
email = email.strip().lower()
name = re.sub(r"[\"',]", "", name).strip()

if not email or "@" not in email:
    sys.exit(0)

def make_key(display_name, addr):
    if display_name:
        parts = [p for p in re.split(r"\s+", display_name) if p]
        if len(parts) == 1:
            key = parts[0]
        else:
            key = f"{parts[-1]}-{parts[0]}"
        key = re.sub(r"[^a-z0-9._+-]+", "-", key.lower()).strip("-")
        if key:
            return key
    return addr

key = make_key(name, email)
if name:
    print(f"alias {key} {name} <{email}>")
else:
    print(f"alias {key} <{email}>")
PY
)

# We never want to create some aliases
NOALIAS_PAT="facebook|twitter|amazon|paypal|ops@exoscale.ch|noreply|no_reply|no-reply|slack|gerrit"

if grep -Eq "$NOALIAS_PAT" <<< "$NEWALIAS"; then
    :
elif grep -Fxq "$NEWALIAS" "$ALIASFILE"; then
    :
else
    echo "$NEWALIAS" >> "$ALIASFILE"
fi

sort -d -i -o "$ALIASFILE" "$ALIASFILE"

echo "${MESSAGE}"
