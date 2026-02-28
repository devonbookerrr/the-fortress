# Automation - PowerShell

Graph API and Azure automation scripts for Fortress configuration collection and enforcement.

## Scripts

| File                              | Purpose                                                           | Status  |
|-----------------------------------|-------------------------------------------------------------------|---------|
| `Get-FortressStatus.ps1`          | Collect Entra ID, CA, and MFA state via Graph API                 | Planned |
| `Set-ConditionalAccessBaseline.ps1` | Idempotent deploy of CA policy set from JSON definitions        | Planned |
| `Invoke-PIMReview.ps1`            | Audit active PIM assignments, flag duration violations            | Planned |
| `Export-ResourceInventory.ps1`    | Pull Azure resource inventory into MySQL via Az module            | Planned |

## Required Modules

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Install-Module Az -Scope CurrentUser
```

## Authentication

All scripts use interactive browser auth by default. For scheduled execution, configure a service principal with certificate-based authentication and update the Connect-MgGraph call to use -ClientId, -TenantId, and -CertificateThumbprint parameters.

## Status: Planned
