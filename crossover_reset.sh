#!/bin/bash

# --- Paths ---
PLIST_DOMAIN="com.codeweavers.CrossOver"
PLIST_PATH="$HOME/Library/Preferences/com.codeweavers.CrossOver.plist"
BOTTLES_DIR="$HOME/Library/Application Support/CrossOver/Bottles"
# Fallback to lowercase if capitalized doesn't exist
if [ ! -d "$BOTTLES_DIR" ]; then
    BOTTLES_DIR="$HOME/Library/Application Support/CrossOver/bottles"
fi

echo "--- CrossOver Maintenance Started ---"

# 1. Safely stop CrossOver
if pgrep -x "CrossOver" > /dev/null; then
    echo "Closing CrossOver..."
    killall "CrossOver"
else
    echo "CrossOver is already closed."
fi

# 2. Reset the 14-day trial timestamp in the plist
if [ -f "$PLIST_PATH" ]; then
    YESTERDAY=$(date -v-1d +"%Y-%m-%d %H:%M:%S +0000")
    defaults write "$PLIST_DOMAIN" FirstRunDate -date "$YESTERDAY"
    echo "✅ Trial date reset to: $YESTERDAY"
else
    echo "⚠️  Global plist not found. Skipping trial date reset."
fi

# 3. Clean the expired registry block with feedback
if [ -d "$BOTTLES_DIR" ]; then
    find "$BOTTLES_DIR" -name "system.reg" | while read -r reg_file; do
        bottle_name=$(basename "$(dirname "$reg_file")")
        
        # Check if the pattern exists before trying to replace it (broad match)
        if grep -qi "Software.*CodeWeavers.*CrossOver.*cxoffice" "$reg_file"; then
            # Perform the multi-line deletion
            perl -i -0777 -pe 's/^\[Software\\+CodeWeavers\\+CrossOver\\+cxoffice\].*?(\n\n|(?=\n\[)|$)/ /gmi' "$reg_file"
            echo "✅ Cleaned expiration block from bottle: $bottle_name"
        else
            echo "ℹ️  Bottle \"$bottle_name\" is already clean."
        fi
    done
else
    echo "⚠️  Bottles directory not found. Skipping registry cleaning."
fi

echo "--- Maintenance Complete ---"
