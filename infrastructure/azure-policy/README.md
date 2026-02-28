# Infrastructure - Azure Policy

Custom Azure Policy definitions and initiative assignments enforcing governance across the subscription.

## Policies

| Policy | Effect | Purpose | Status |
|--------|--------|---------|--------|
| Require environment tag | Deny | Block resource creation without environment tag | Planned |
| Require project tag | Deny | Block resource creation without project tag | Planned |
| Require owner tag | Deny | Block resource creation without owner tag | Planned |
| Allowed locations | Deny | Restrict resources to approved Azure regions | Planned |
| Allowed VM SKUs | Deny | Restrict VM sizes to cost-approved list | Planned |
| Require HTTPS on Storage | Deny | Block HTTP traffic to Azure Storage | Planned |
| Require TLS 1.2 minimum | Deny | Block older TLS versions on storage and SQL | Planned |
| Deploy diagnostic settings | DeployIfNotExists | Auto-deploy Log Analytics diagnostic settings on new resources | Planned |

## Initiative

All policies are bundled into a single initiative: `Fortress Governance Baseline`.
The initiative is assigned at the subscription scope.

## Status: Planned
