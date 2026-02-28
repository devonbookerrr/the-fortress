# Linux - Monitoring

Azure Monitor Agent configuration for the Ubuntu Server node.

## Data Sources Collected

| Source | Data | Destination |
|--------|------|-------------|
| Syslog (auth, authpriv) | SSH logins, sudo, PAM events | Log Analytics |
| Syslog (cron) | Cron job execution | Log Analytics |
| Auditd | File access, privilege escalation, user management | Log Analytics |
| Performance counters | CPU, memory, disk, network | Log Analytics |

## Agent Installation

```bash
# Download and install Azure Monitor Agent
wget https://aka.ms/AMALinux -O install-ama.sh
chmod +x install-ama.sh
sudo bash install-ama.sh
```

## Data Collection Rule

A DCR (Data Collection Rule) defines what data the agent collects and where it sends it.
Deployed via Bicep as part of the Fortress infrastructure deployment.

## Status: Planned
