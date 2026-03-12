#!/bin/bash

# Unique marker to identify our cron job (used for idempotency)
CRON_MARKER="# crossover-reset-daily"

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESET_SCRIPT="$SCRIPT_DIR/crossover_reset.sh"

# Validate that crossover_reset.sh exists
if [ ! -f "$RESET_SCRIPT" ]; then
    echo "Error: crossover_reset.sh not found at $RESET_SCRIPT"
    exit 1
fi

# Make sure the reset script is executable
chmod +x "$RESET_SCRIPT"

echo "Installing hourly cron job for crossover_reset.sh"

# Get current crontab, excluding our job to avoid duplicates
TEMP_CRON=$(mktemp)
(crontab -l 2>/dev/null | grep -v "$CRON_MARKER" | grep -v "crossover_reset.sh") > "$TEMP_CRON" || true

# Add our job (marker at end so # doesn't break the redirect)
LOG_FILE="$HOME/Library/Logs/crossover_reset.log"
echo "0 * * * * $RESET_SCRIPT >> \"$LOG_FILE\" 2>&1 $CRON_MARKER" >> "$TEMP_CRON"

# Install the new crontab
crontab "$TEMP_CRON"
rm -f "$TEMP_CRON"

echo "✅ Cron job installed. Output will be logged to $HOME/Library/Logs/crossover_reset.log"
echo "Current cron entry:"
crontab -l 2>/dev/null | grep "crossover_reset" || echo "(none found)"
