# Infrastructure - Bicep

IaC templates for all Azure resources in The Fortress.

## Deployment Order

1. `vnet-hub.bicep` - Hub VNet and central resources
2. `vnet-spoke-prod.bicep` - Production spoke and peering
3. `vnet-spoke-dev.bicep` - Dev spoke and peering

## Conventions

- All resources tagged: `environment`, `project`, `owner`, `cost-center`
- Parameters in separate `.bicepparam` files - never hardcoded
- Secrets referenced from Key Vault, never passed as plain text
- Diagnostic settings on every resource pointing to central Log Analytics workspace

## Status: Planned
