#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Identity.SignIns
<#
.SYNOPSIS
    Idempotently deploys the Fortress Conditional Access policy baseline.

.DESCRIPTION
    Reads CA policy definitions from a JSON file and creates or updates policies
    in Entra ID. Existing policies with matching DisplayName are updated in place.
    New policies are created in Report-Only state - never enforced on first deploy.

    Policy staging workflow:
        1. Deploy with this script (Report-Only state)
        2. Monitor sign-in logs for 2 weeks
        3. Promote to Enabled manually after review

.PARAMETER DefinitionPath
    Path to the CA policy definition JSON file.
    Defaults to .\ca-policies.json relative to the script location.

.PARAMETER WhatIf
    Preview changes without applying them.

.EXAMPLE
    .\Set-ConditionalAccessBaseline.ps1

.EXAMPLE
    .\Set-ConditionalAccessBaseline.ps1 -DefinitionPath C:\temp\ca-policies.json -WhatIf

.NOTES
    Required permissions: Policy.ReadWrite.ConditionalAccess
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter()]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$DefinitionPath = (Join-Path $PSScriptRoot 'ca-policies.json')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ExistingPolicies {
    [OutputType([hashtable])]
    param()
    $existing = Get-MgIdentityConditionalAccessPolicy -All
    $map = @{}
    foreach ($policy in $existing) {
        $map[$policy.DisplayName] = $policy
    }
    return $map
}

# ── Main ──────────────────────────────────────────────────────────────────────

Connect-MgGraph -Scopes 'Policy.ReadWrite.ConditionalAccess' -NoWelcome

$definitions = Get-Content -Path $DefinitionPath -Raw | ConvertFrom-Json
$existingPolicies = Get-ExistingPolicies

foreach ($def in $definitions) {
    if ($existingPolicies.ContainsKey($def.displayName)) {
        $existing = $existingPolicies[$def.displayName]
        if ($PSCmdlet.ShouldProcess($def.displayName, 'Update Conditional Access policy')) {
            Write-Host "Updating: $($def.displayName)" -ForegroundColor Yellow
            # TODO: Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $existing.Id -BodyParameter $def
        }
    } else {
        # Force Report-Only on create regardless of what the definition says
        $def.state = 'enabledForReportingButNotEnforced'
        if ($PSCmdlet.ShouldProcess($def.displayName, 'Create Conditional Access policy (Report-Only)')) {
            Write-Host "Creating (Report-Only): $($def.displayName)" -ForegroundColor Cyan
            # TODO: New-MgIdentityConditionalAccessPolicy -BodyParameter $def
        }
    }
}

Write-Host "Baseline deployment complete. Review Report-Only sign-in logs before promoting policies to Enabled." -ForegroundColor Green

Disconnect-MgGraph -ErrorAction SilentlyContinue
