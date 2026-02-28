#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Identity.SignIns, Microsoft.Graph.Identity.DirectoryManagement
<#
.SYNOPSIS
    Collects current security control state from Entra ID and M365 via Graph API.

.DESCRIPTION
    Queries Conditional Access policies, MFA registration, privileged role assignments,
    authentication method policies, and legacy auth state. Outputs a structured PSObject
    suitable for comparison against a known-good baseline or insertion into MySQL.

.PARAMETER TenantId
    Entra ID tenant ID. Defaults to the connected tenant.

.PARAMETER OutputPath
    Optional path to write JSON output. If omitted, outputs to pipeline.

.PARAMETER IncludeUsers
    If specified, includes per-user MFA registration state. Can be slow in large tenants.

.EXAMPLE
    .\Get-FortressStatus.ps1 -OutputPath C:\temp\fortress-status.json

.EXAMPLE
    .\Get-FortressStatus.ps1 -IncludeUsers | ConvertTo-Json -Depth 10

.NOTES
    Required Graph API permissions (application or delegated):
        Policy.Read.All
        User.Read.All
        RoleManagement.Read.All
        UserAuthenticationMethod.Read.All
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$TenantId,

    [Parameter()]
    [string]$OutputPath,

    [Parameter()]
    [switch]$IncludeUsers
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Connect-FortressGraph {
    [CmdletBinding()]
    param (
        [string]$TenantId
    )

    $connectParams = @{
        Scopes = @(
            'Policy.Read.All'
            'User.Read.All'
            'RoleManagement.Read.All'
            'UserAuthenticationMethod.Read.All'
        )
    }

    if ($TenantId) {
        $connectParams['TenantId'] = $TenantId
    }

    Write-Verbose "Connecting to Microsoft Graph..."
    Connect-MgGraph @connectParams
}

function Get-ConditionalAccessState {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[PSObject]])]
    param()

    Write-Verbose "Collecting Conditional Access policies..."

    $policies = Get-MgIdentityConditionalAccessPolicy -All

    $result = [System.Collections.Generic.List[PSObject]]::new()

    foreach ($policy in $policies) {
        $result.Add([PSCustomObject]@{
            PolicyId          = $policy.Id
            DisplayName       = $policy.DisplayName
            State             = $policy.State
            CreatedDateTime   = $policy.CreatedDateTime
            ModifiedDateTime  = $policy.ModifiedDateTime
            IncludedUsers     = $policy.Conditions.Users.IncludeUsers -join ','
            ExcludedUsers     = $policy.Conditions.Users.ExcludeUsers -join ','
            IncludedGroups    = $policy.Conditions.Users.IncludeGroups -join ','
            ExcludedGroups    = $policy.Conditions.Users.ExcludeGroups -join ','
            GrantControls     = $policy.GrantControls.BuiltInControls -join ','
            SessionControls   = ($policy.SessionControls | ConvertTo-Json -Compress)
        })
    }

    return $result
}

function Get-PrivilegedRoleState {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[PSObject]])]
    param()

    Write-Verbose "Collecting privileged role assignments..."

    # TODO: Switch to PIM eligible assignments once PIM module is added
    $roleAssignments = Get-MgRoleManagementDirectoryRoleAssignment -All -ExpandProperty Principal

    $privilegedRoles = @(
        'Global Administrator'
        'Security Administrator'
        'Exchange Administrator'
        'User Access Administrator'
        'Privileged Role Administrator'
    )

    $result = [System.Collections.Generic.List[PSObject]]::new()

    foreach ($assignment in $roleAssignments) {
        $roleDef = Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $assignment.RoleDefinitionId

        if ($roleDef.DisplayName -in $privilegedRoles) {
            $result.Add([PSCustomObject]@{
                AssignmentId     = $assignment.Id
                RoleName         = $roleDef.DisplayName
                RoleDefinitionId = $assignment.RoleDefinitionId
                PrincipalId      = $assignment.PrincipalId
                PrincipalType    = $assignment.Principal.AdditionalProperties.'@odata.type'
                PrincipalName    = $assignment.Principal.AdditionalProperties.displayName
                AssignmentType   = 'Active'  # TODO: Add PIM eligible assignments
                DirectoryScopeId = $assignment.DirectoryScopeId
            })
        }
    }

    return $result
}

function Get-LegacyAuthState {
    [CmdletBinding()]
    [OutputType([PSObject])]
    param()

    Write-Verbose "Collecting authentication method policies..."

    # TODO: Query sign-in logs for legacy auth activity over last 30 days
    # Requires AuditLog.Read.All permission
    # For now returns policy state only

    $authMethodPolicy = Get-MgPolicyAuthenticationMethodPolicy

    return [PSCustomObject]@{
        PolicyId             = $authMethodPolicy.Id
        Description          = $authMethodPolicy.Description
        LastModifiedDateTime = $authMethodPolicy.LastModifiedDateTime
        # TODO: Parse per-method enable/disable state
    }
}

# ── Main ──────────────────────────────────────────────────────────────────────

try {
    Connect-FortressGraph -TenantId $TenantId

    $status = [PSCustomObject]@{
        CollectedAt          = (Get-Date -Format 'o')
        TenantId             = (Get-MgContext).TenantId
        ConditionalAccess    = Get-ConditionalAccessState
        PrivilegedRoles      = Get-PrivilegedRoleState
        LegacyAuthPolicy     = Get-LegacyAuthState
    }

    if ($IncludeUsers) {
        Write-Verbose "Collecting per-user MFA registration state (this may take a while)..."
        # TODO: Implement Get-MgReportAuthenticationMethodUserRegistrationDetail
        Write-Warning "IncludeUsers not yet implemented."
    }

    if ($OutputPath) {
        $status | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
        Write-Verbose "Output written to $OutputPath"
    } else {
        return $status
    }
}
catch {
    Write-Error "Get-FortressStatus failed: $_"
    throw
}
finally {
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}
