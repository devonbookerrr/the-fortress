# M365 - Intune

Device compliance and configuration profile documentation.

## Compliance Policies

| File | Platform | Status |
|------|----------|--------|
| `compliance-policy-windows.json` | Windows 11 | Planned |

## Key Requirements

- BitLocker enabled
- Secure Boot enabled
- Defender real-time protection active
- Minimum OS version enforced
- Password complexity minimum 12 characters

## Non-Compliant Device Action

1 day grace period, then mark non-compliant. CA005 blocks unmanaged/non-compliant devices from full app access and enforces app-restricted sessions.

## Status: Planned
