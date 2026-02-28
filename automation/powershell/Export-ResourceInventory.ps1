#Requires -Modules Az.Accounts, Az.Resources
<#
.SYNOPSIS
    Pulls Azure resource inventory and writes it to the Fortress MySQL database.

.DESCRIPTION
    Enumerates all resources in the connected subscription, collects tags, resource type,
    location, and resource group, then upserts into the resource_inventory table in MySQL.
    Flags resources missing required tags as compliance findings.

.PARAMETER SubscriptionId
    Azure subscription ID. Defaults to the current Az context subscription.

.PARAMETER MySqlServer
    MySQL server hostname or IP. Defaults to localhost (Ubuntu node).

.PARAMETER MySqlDatabase
    MySQL database name. Defaults to 'fortress'.

.PARAMETER RequiredTags
    Array of tag keys that must be present on all resources.
    Defaults to the Fortress tagging policy.

.EXAMPLE
    .\Export-ResourceInventory.ps1

.EXAMPLE
    .\Export-ResourceInventory.ps1 -SubscriptionId 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' -MySqlServer '10.1.2.10'

.NOTES
    Requires MySql.Data .NET connector or mysql command-line client on PATH.
    Required Az permissions: Reader on subscription scope.
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$SubscriptionId,

    [Parameter()]
    [string]$MySqlServer = 'localhost',

    [Parameter()]
    [string]$MySqlDatabase = 'fortress',

    [Parameter()]
    [string[]]$RequiredTags = @('environment', 'project', 'owner', 'managedBy')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

Write-Verbose "Collecting Azure resource inventory..."

$resources = Get-AzResource -ExpandProperties

$inventory = [System.Collections.Generic.List[PSObject]]::new()
$missingTags = [System.Collections.Generic.List[PSObject]]::new()

foreach ($resource in $resources) {
    $inventory.Add([PSCustomObject]@{
        ResourceId    = $resource.ResourceId
        ResourceName  = $resource.Name
        ResourceType  = $resource.ResourceType
        ResourceGroup = $resource.ResourceGroupName
        Location      = $resource.Location
        Tags          = ($resource.Tags | ConvertTo-Json -Compress)
        CollectedAt   = (Get-Date -Format 'o')
    })

    foreach ($tag in $RequiredTags) {
        if (-not $resource.Tags.ContainsKey($tag)) {
            $missingTags.Add([PSCustomObject]@{
                ResourceId   = $resource.ResourceId
                ResourceName = $resource.Name
                MissingTag   = $tag
                Severity     = 'Medium'
            })
        }
    }
}

Write-Host "Resources collected: $($inventory.Count)" -ForegroundColor Cyan
Write-Host "Tag compliance findings: $($missingTags.Count)" -ForegroundColor Yellow

# TODO: Write $inventory to resource_inventory MySQL table
# TODO: Write $missingTags to compliance_findings MySQL table
# TODO: Use MySqlConnector module or invoke mysql CLI with here-string SQL

$inventory | Format-Table ResourceName, ResourceType, ResourceGroup, Location -AutoSize
