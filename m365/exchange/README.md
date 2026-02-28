# M365 - Exchange Online

Exchange Online security hardening configuration.

## Controls

| Control | Setting | Status |
|---------|---------|--------|
| Anti-Phishing | Mailbox intelligence, impersonation protection, spoof intelligence enabled | Planned |
| External Tagging | External sender tag on all inbound email | Planned |
| Audit Logging | 180-day audit log retention | Planned |
| Legacy Auth | SMTP client auth disabled at protocol layer | Planned |
| Attachment Blocking | 30+ dangerous file extensions blocked and quarantined | Planned |
| DMARC Enforcement | Reject policy for the fortress domain | Planned |

## Deployment

```powershell
Connect-ExchangeOnline
.\exchange-hardening.ps1
```

## Status: Planned
