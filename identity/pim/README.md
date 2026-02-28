# Identity - Privileged Identity Management

PIM role settings and eligible assignment documentation.

## Policy

All privileged roles are eligible-only. No permanent active admin assignments except the documented break-glass account.

PIM settings are defined in `pim-settings.json` and applied manually via the Entra ID portal or the PIM REST API.

## Role Settings

| Role | Max Duration | Approval | Justification |
|------|-------------|----------|---------------|
| Global Administrator | 1 hour | Required | Required |
| Security Administrator | 4 hours | Not required | Required |
| Exchange Administrator | 4 hours | Not required | Required |
| User Access Administrator | 2 hours | Required | Required |
| SharePoint Administrator | 4 hours | Not required | Required |

## Break-Glass Account

One permanent active Global Administrator account for emergency access.

- Excluded from all Conditional Access policies
- MFA registered with hardware key
- Credentials stored in sealed physical envelope
- Alert rule in Sentinel fires on any sign-in from this account
- Access log reviewed monthly

## ADR Reference

ADR-002 - PIM Eligible-Only Policy

## Status: Planned
