#!/usr/bin/env bash
# The Fortress - Automated System Update
# Runs unattended-upgrades for security patches.
# Logs output to syslog and local log file.
# Status: Planned

set -euo pipefail

readonly LOG_FILE="/var/log/fortress-updates.log"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg" | tee -a "$LOG_FILE"
    logger -t fortress-update "$msg"
}

log "Starting system update check"

# Refresh package index
apt-get update -qq 2>&1 | tee -a "$LOG_FILE"

# Apply security updates only
unattended-upgrade -v 2>&1 | tee -a "$LOG_FILE"

# Check if reboot is required
if [ -f /var/run/reboot-required ]; then
    log "NOTICE: Reboot required. Packages updated:"
    cat /var/run/reboot-required.pkgs | tee -a "$LOG_FILE"
    # TODO: Send Teams notification via webhook if reboot is required
fi

log "Update check complete."
