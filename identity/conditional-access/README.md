# Identity - Conditional Access

CA policy definitions and deployment documentation.

## Policy Set

Policies are defined in `ca-policies.json` and deployed via `Set-ConditionalAccessBaseline.ps1`.

All policies are created in **Report-Only** state on first deploy. Promote to **Enabled** after 2+ weeks of sign-in log review.

| Policy ID | Name | Status |
|-----------|------|--------|
| CA001 | All Users - Require MFA | Planned |
| CA002 | Admin Roles - Require Phishing-Resistant MFA | Planned |
| CA003 | All Users - Block Legacy Authentication | Planned |
| CA004 | High Risk Sign-In - Force Reauthentication | Planned |
| CA005 | Unmanaged Devices - App Enforced Restrictions | Planned |

## Pre-Deployment Checklist

- [ ] Break-glass account created and documented
- [ ] Break-glass account excluded from all CA policies
- [ ] Break-glass account MFA method registered
- [ ] Named Locations defined for trusted corporate IPs
- [ ] All placeholder IDs in ca-policies.json replaced with real object IDs
- [ ] Phishing-resistant MFA authentication strength policy created
- [ ] Sign-in logs reviewed in Report-Only for minimum 2 weeks before enforcement

## Naming Convention

`CA[###] - [Scope] - [Action]`

## Status: Planned
