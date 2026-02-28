#!/usr/bin/env bash
# The Fortress - Ubuntu Server 24.04 CIS Level 2 Hardening
# Run as root on a fresh Ubuntu Server 24.04 install.
# Idempotent - safe to run multiple times.
# Status: Planned (implementation TODOs inline)

set -euo pipefail

readonly SCRIPT_NAME=$(basename "$0")
readonly LOG_FILE="/var/log/fortress-cis-hardening.log"
readonly TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# ── Logging ───────────────────────────────────────────────────────────────────

log() {
    echo "[${TIMESTAMP}] [${SCRIPT_NAME}] $*" | tee -a "$LOG_FILE"
}

log_section() {
    log "────────────────────────────────────────"
    log "SECTION: $*"
    log "────────────────────────────────────────"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Error: This script must be run as root." >&2
        exit 1
    fi
}

# ── CIS 1.1 - Filesystem Configuration ───────────────────────────────────────

harden_filesystem() {
    log_section "1.1 Filesystem Configuration"

    # CIS 1.1.1 - Disable unused filesystems
    log "1.1.1 - Disabling unused filesystem modules"
    local unused_fs=(cramfs freevxfs jffs2 hfs hfsplus squashfs udf usb-storage)
    for fs in "${unused_fs[@]}"; do
        if ! grep -q "install ${fs} /bin/true" /etc/modprobe.d/fortress-cis.conf 2>/dev/null; then
            echo "install ${fs} /bin/true" >> /etc/modprobe.d/fortress-cis.conf
            log "  Disabled: ${fs}"
        fi
    done

    # CIS 1.1.2 - /tmp on separate partition or tmpfs with noexec,nosuid,nodev
    log "1.1.2 - Configuring /tmp mount options"
    # TODO: Check if /tmp is on a separate partition
    # TODO: If tmpfs, ensure noexec,nosuid,nodev options are set in /etc/fstab
    # TODO: Remount if options are missing: mount -o remount,noexec,nosuid,nodev /tmp

    # CIS 1.1.3 - /home on separate partition
    log "1.1.3 - Checking /home partition (manual verification required)"
    # TODO: Verify /home is on a dedicated partition
    # NOTE: This should be configured at install time - cannot be automated post-install
}

# ── CIS 2 - Services ─────────────────────────────────────────────────────────

harden_services() {
    log_section "2 - Disable Unnecessary Services"

    local disable_services=(
        avahi-daemon
        cups
        isc-dhcp-server
        isc-dhcp-server6
        slapd
        nfs-server
        rpcbind
        bind9
        vsftpd
        apache2
        dovecot
        smbd
        squid
        snmpd
        rsync
        nis
    )

    for svc in "${disable_services[@]}"; do
        if systemctl is-enabled "$svc" &>/dev/null; then
            systemctl disable --now "$svc"
            log "  Disabled: ${svc}"
        fi
    done
}

# ── CIS 3 - Network Configuration ────────────────────────────────────────────

harden_network() {
    log_section "3 - Network Configuration"

    log "3.1 - Applying kernel network hardening parameters"
    cat > /etc/sysctl.d/99-fortress-cis.conf << 'EOF'
# CIS Level 2 - Network hardening
# 3.1 - Disable IP forwarding (not a router)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# 3.2 - Disable packet redirect sending
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# 3.3 - Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# 3.4 - Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# 3.5 - Enable reverse path filtering
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# 3.6 - Enable TCP SYN cookies
net.ipv4.tcp_syncookies = 1

# 3.7 - Log suspicious packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
EOF

    sysctl -p /etc/sysctl.d/99-fortress-cis.conf
    log "  Kernel parameters applied"
}

# ── CIS 4 - Host-Based Firewall (UFW) ─────────────────────────────────────────

configure_firewall() {
    log_section "4 - Host-Based Firewall"

    log "4.1 - Configuring UFW"

    apt-get install -y ufw > /dev/null 2>&1

    ufw --force reset

    # Default policies
    ufw default deny incoming
    ufw default allow outgoing
    ufw default deny routed

    # Allow SSH - restrict to management subnet only in production
    # TODO: Replace with actual management subnet CIDR
    ufw allow from 10.0.3.0/28 to any port 22 proto tcp comment "SSH from management subnet"

    # Allow MySQL from application subnet only
    # TODO: Replace with actual application subnet CIDR
    ufw allow from 10.1.1.0/24 to any port 3306 proto tcp comment "MySQL from app subnet"

    # Allow Azure Monitor Agent outbound
    ufw allow out to any port 443 proto tcp comment "HTTPS outbound for Azure Monitor"

    ufw --force enable
    log "  UFW configured and enabled"
    ufw status verbose | tee -a "$LOG_FILE"
}

# ── CIS 5 - Access, Authentication, and Authorization ────────────────────────

harden_access() {
    log_section "5 - Access, Authentication, and Authorization"

    log "5.1 - Configuring SSH"
    local sshd_config="/etc/ssh/sshd_config.d/99-fortress-cis.conf"
    cat > "$sshd_config" << 'EOF'
# CIS Level 2 - SSH hardening

Protocol 2
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
IgnoreRhosts yes
HostbasedAuthentication no
X11Forwarding no
MaxAuthTries 4
LoginGraceTime 60
ClientAliveInterval 300
ClientAliveCountMax 0
AllowTcpForwarding no
AllowAgentForwarding no
Banner /etc/issue.net
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

    echo "Authorized use only. All connections are monitored and logged." > /etc/issue.net

    sshd -t && systemctl reload ssh
    log "  SSH hardened"

    log "5.2 - Configuring PAM password policy"
    # TODO: Configure pam_pwquality in /etc/security/pwquality.conf
    # TODO: minlen=14, minclass=4, maxrepeat=3, maxsequence=3, dcredit=-1, ucredit=-1, lcredit=-1, ocredit=-1

    log "5.3 - Configuring account lockout (pam_faillock)"
    # TODO: Configure /etc/security/faillock.conf
    # TODO: deny=5, unlock_time=900, even_deny_root=yes

    log "5.4 - Configuring password expiration in /etc/login.defs"
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   365/' /etc/login.defs
    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   1/'   /etc/login.defs
    sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   14/'  /etc/login.defs
    log "  Password aging configured"
}

# ── CIS 6 - System Maintenance ────────────────────────────────────────────────

configure_auditing() {
    log_section "6 - System Maintenance and Auditing"

    log "6.1 - Installing and configuring auditd"
    apt-get install -y auditd audispd-plugins > /dev/null 2>&1

    # TODO: Deploy CIS auditd ruleset to /etc/audit/rules.d/fortress-cis.rules
    # Reference: https://github.com/Neo23x0/auditd/blob/master/audit.rules
    # Key rules to include:
    #   - Monitor /etc/passwd, /etc/shadow, /etc/group modifications
    #   - Monitor sudoers changes
    #   - Log all privileged command executions
    #   - Log failed file access attempts
    #   - Log user/group management commands

    systemctl enable --now auditd
    log "  Auditd installed and enabled"

    log "6.2 - Installing and configuring AIDE (file integrity)"
    apt-get install -y aide aide-common > /dev/null 2>&1

    # TODO: Configure /etc/aide/aide.conf with appropriate file coverage
    # TODO: Initialize database: aide --init
    # TODO: Install cron job: run aide --check daily, log results to syslog

    log "6.3 - Installing and configuring Fail2Ban"
    apt-get install -y fail2ban > /dev/null 2>&1
    # TODO: Configure /etc/fail2ban/jail.local
    #   sshd: maxretry=5, bantime=3600, findtime=600

    systemctl enable --now fail2ban
    log "  Fail2ban installed and enabled"
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
    check_root

    log "Starting CIS Level 2 hardening for Ubuntu Server 24.04"
    log "Host: $(hostname) | IP: $(hostname -I | awk '{print $1}')"

    harden_filesystem
    harden_services
    harden_network
    configure_firewall
    harden_access
    configure_auditing

    log "CIS hardening complete. Review log at: ${LOG_FILE}"
    log "IMPORTANT: Reboot required for all settings to take effect."
    log "IMPORTANT: Verify SSH access works before disconnecting current session."
}

main "$@"
