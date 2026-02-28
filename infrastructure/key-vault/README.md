# Infrastructure - Key Vault

Key Vault configuration and access control model.

## Design

- RBAC authorization model (not legacy access policies)
- Private endpoint only - no public network access
- Soft delete with 90-day retention
- Purge protection enabled
- All operations logged to central Log Analytics workspace

## Secrets Stored

| Secret Name | Purpose | Rotation Schedule |
|-------------|---------|-------------------|
| fortress-db-password | MySQL application user password | 90 days |
| fortress-backup-sas | Azure Blob SAS token for MySQL backups | 30 days |
| smtp-relay-password | SMTP relay credentials for notifications | 90 days |

## Access Model

| Principal | Role | Scope |
|-----------|------|-------|
| Fortress automation service principal | Key Vault Secrets User | All secrets |
| Devon Booker (eligible via PIM) | Key Vault Administrator | Full vault |

## Deployment

Deployed via `infrastructure/bicep/key-vault.bicep`.

## Status: Planned
