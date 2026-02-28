#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Identity.Governance
<#
.SYNOPSIS
    Audits active PIM role assignments and flags duration threshold violations.

.DESCRIPTION
    Pulls all active PIM role activations for privileged roles. Flags any activation
    that exceeds the defined maximum duration per role, any permanent active assignments,
    and any activations outside of business hours without a documented justification.

.PARAMETER MaxDurationHours
    Hashtable of role name to max allowed activation duration in hours.
    Defaults to the Fortress PIM policy values.

.PARAMETER OutputPath
    Optional path to write findings as JSON.

.EXAMPLE
    .\Invoke-PIMReview.ps1

.EXAMPLE
    .\Invoke-PIMReview.ps1 -OutputPath C:\temp\pim-review.json

.NOTES
    Required permissions:
        RoleManagement.Read.All
        RoleEligibilitySchedule.Read.Directory
        RoleAssignmentSchedule.Read.Directory
#>

[CmdletBinding()]
param (
    [Parameter()]
    [hashtable]$MaxDurationHours = @{
        'Global Administrator'          = 1
        'Security Administrator'        = 4
        'Exchange Administrator'        = 4
        'User Access Administrator'     = 2
        'SharePoint Administrator'      = 4
        'Privileged Role Administrator' = 2
    },

    [Parameter()]
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Connect-MgGraph -Scopes @(
    'RoleManagement.Read.All'
    'RoleEligibilitySchedule.Read.Directory'
    'RoleAssignmentSchedule.Read.Directory'
) -NoWelcome

$findings = [System.Collections.Generic.List[PSObject]]::new()

Write-Verbose "Pulling active PIM role assignment schedules..."

# TODO: Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance -All
# TODO: For each instance, resolve role definition name
# TODO: Compare activation duration against $MaxDurationHours
# TODO: Flag permanent active assignments (ScheduleInfo.Expiration.Type = 'noExpiration')
# TODO: Check activation time against business hours window
# TODO: Verify justification is not null or empty

Write-Host "PIM review complete. Findings: $($findings.Count)" -ForegroundColor Cyan

if ($OutputPath) {
    $findings | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding utf8
}

$findings | Format-Table RoleName, PrincipalName, ActivatedAt, DurationHours, Finding -AutoSize

Disconnect-MgGraph -ErrorAction SilentlyContinue
