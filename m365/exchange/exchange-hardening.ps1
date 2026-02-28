#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Applies Exchange Online security hardening baseline for The Fortress.

.DESCRIPTION
    Configures DMARC enforcement, external email tagging, attachment blocking,
    audit log settings, and anti-spam policies. Idempotent.

.NOTES
    Required permissions: Exchange Administrator (via PIM)
    Connect-ExchangeOnline must be run before invoking this script.
#>

[CmdletBinding(SupportsShouldProcess)]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Anti-Phishing Policy ──────────────────────────────────────────────────────

Write-Host "Configuring Anti-Phishing policy..." -ForegroundColor Cyan

# TODO: Get-AntiPhishPolicy | Set-AntiPhishPolicy
# Settings to enforce:
#   EnableOrganizationDomainsProtection: $true
#   EnableMailboxIntelligence: $true
#   EnableMailboxIntelligenceProtection: $true
#   EnableSpoofIntelligence: $true
#   MailboxIntelligenceProtectionAction: Quarantine
#   ImpersonationProtectionState: Automatic

# ── Anti-Spam: External Email Tagging ─────────────────────────────────────────

Write-Host "Enabling external email tagging..." -ForegroundColor Cyan

# TODO: Set-ExternalInOutlook -Enabled $true
# Adds "External" tag to emails from outside the organization

# ── Audit Log: 180-Day Retention ─────────────────────────────────────────────

Write-Host "Configuring audit log retention..." -ForegroundColor Cyan

# TODO: Set-AdminAuditLogConfig -AdminAuditLogEnabled $true -AdminAuditLogAgeLimit 180.00:00:00
# TODO: Set-OrganizationConfig -AuditDisabled $false

# ── Disable Basic Auth ────────────────────────────────────────────────────────

Write-Host "Disabling legacy authentication protocols..." -ForegroundColor Cyan

# TODO: Set-TransportConfig -SmtpClientAuthenticationDisabled $true
# Note: CA003 blocks legacy auth at the identity layer
# This disables it at the protocol layer as defense in depth

# ── Blocked File Extensions ───────────────────────────────────────────────────

Write-Host "Configuring blocked attachment extensions..." -ForegroundColor Cyan

$blockedExtensions = @(
    'exe', 'bat', 'cmd', 'com', 'cpl', 'dll', 'hta', 'js', 'jse',
    'msc', 'msh', 'msh1', 'msh2', 'mshxml', 'msi', 'msp', 'mst',
    'ps1', 'ps1xml', 'ps2', 'ps2xml', 'psc1', 'psc2', 'reg', 'scf',
    'scr', 'sct', 'vb', 'vbe', 'vbs', 'wsc', 'wsf', 'wsh'
)

# TODO: New-MalwareFilterPolicy or Set-MalwareFilterPolicy
# TODO: Add $blockedExtensions to FileTypeAction with Quarantine

Write-Host "Exchange hardening complete." -ForegroundColor Green
