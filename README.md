# The Fortress

A production-grade Microsoft 365 + Azure + Linux + MySQL environment built from scratch and maintained as a living portfolio.

This is not a sandbox. It is a documented, operational environment I use to test, validate, and demonstrate everything I build across cloud infrastructure, identity security, and automation engineering. Every architectural decision is logged. Every configuration is versioned. Every component exists to serve a real security or infrastructure objective.

---

## Architecture

The Fortress is organized around three pillars, all governed by a central Entra ID identity layer.

**Microsoft Entra ID** sits at the top of the stack and controls access to everything. Conditional Access policies, PIM role assignments, and authentication method policies enforce identity-first access across M365, Azure, and the Linux node.

**Azure Infrastructure** uses a hub-and-spoke VNet topology. The hub hosts the Azure Firewall, DNS Resolver, and VPN Gateway. Two spokes - production and development - connect to the hub with all inter-spoke traffic routed through the hub firewall via UDRs. Key Vault manages all secrets and certificates centrally. Every resource ships diagnostic logs to a central Log Analytics workspace.

**Ubuntu Server 24.04** is the Linux node, hardened to CIS Level 2. It hosts the MySQL instance that backs the Assessment Engine and the architectural decision log. SSH key-only, UFW locked down, Auditd running the CIS ruleset, AIDE on a daily schedule.

**Microsoft 365** sits alongside Azure, governed by the same Entra ID identity layer. Exchange Online, Intune, Defender for Office 365 P2, DLP, and Information Protection are all configured from a security-first baseline.

---

## Repository Structure

```
the-fortress/
├── infrastructure/          Azure IaC and governance
│   ├── bicep/               Bicep templates for all Azure resources
│   ├── azure-policy/        Custom policy definitions and initiative
│   └── key-vault/           Key Vault configuration and access model
├── identity/                Entra ID configuration
│   ├── conditional-access/  CA policy set definitions
│   ├── pim/                 PIM role settings and eligible assignments
│   └── entra-id/            Tenant-level authentication and user settings
├── linux/                   Ubuntu Server administration
│   ├── hardening/           CIS Level 2 hardening scripts
│   ├── automation/          System administration bash scripts
│   └── monitoring/          Log collection and agent configuration
├── m365/                    Microsoft 365 security configuration
│   ├── exchange/            Exchange Online hardening
│   ├── intune/              Device compliance and configuration profiles
│   └── defender/            Defender for Office 365 policy configuration
├── database/                MySQL schema and reference queries
│   ├── schema/              Table definitions
│   └── queries/             Reference queries for the decision log
├── automation/              Cross-platform scripting
│   ├── powershell/          Graph API and Azure automation scripts
│   └── python/              Reporting and drift detection scripts
└── docs/                    Architecture and decision records
    ├── architecture/        Diagrams and design documentation
    └── decisions/           Architectural Decision Records (ADRs)
```

---

## Infrastructure

### Hub-and-Spoke VNet Topology

The hub VNet (10.0.0.0/16) hosts centralized services: Azure Firewall in AzureFirewallSubnet (10.0.1.0/26), VPN Gateway in GatewaySubnet (10.0.2.0/27), and management resources in ManagementSubnet (10.0.3.0/28). Two spoke VNets peer to the hub with AllowGatewayTransit enabled. All spoke-to-spoke traffic routes through the hub firewall - no direct peering between spokes.

| VNet               | Address Space  | Key Subnets                                       |
|--------------------|----------------|---------------------------------------------------|
| Hub                | 10.0.0.0/16    | Firewall /26, Gateway /27, Management /28         |
| Spoke: Production  | 10.1.0.0/16    | Application /24, Data /24                        |
| Spoke: Dev         | 10.2.0.0/16    | Workload /24                                      |

### Security Controls

- Azure Policy initiative enforcing resource tagging, allowed regions, and SKU restrictions
- Key Vault with RBAC authorization model, private endpoint only, soft delete and purge protection enabled
- All resources emit diagnostic logs to a central Log Analytics workspace
- Microsoft Defender for Cloud enabled with enhanced protections across the subscription
- No permanent privileged role assignments - all admin access via PIM

---

## Identity

### Conditional Access Policy Set

Policies use the naming convention `CA[###] - [Scope] - [Action]` and are staged in Report-Only for two weeks before enforcement.

| Policy ID | Scope             | Action                         | State   |
|-----------|-------------------|--------------------------------|---------|
| CA001     | All Users         | Require MFA                    | Planned |
| CA002     | Admin Roles       | Require Phishing-Resistant MFA | Planned |
| CA003     | All Users         | Block Legacy Authentication    | Planned |
| CA004     | High Risk Sign-In | Force Reauthentication         | Planned |
| CA005     | Unmanaged Devices | App-Enforced Restrictions      | Planned |

Named Locations are defined before any policy references them. Exclusion groups for break-glass and service accounts are documented per policy.

### Privileged Identity Management

All privileged roles are eligible-only. No permanent active admin assignments except the documented break-glass account, which is excluded from all Conditional Access policies and monitored via an alert rule.

| Role                      | Max Duration | Approval Required | Justification Required |
|---------------------------|--------------|-------------------|------------------------|
| Global Administrator      | 1 hour       | Yes               | Yes                    |
| Security Administrator    | 4 hours      | No                | Yes                    |
| Exchange Administrator    | 4 hours      | No                | Yes                    |
| User Access Administrator | 2 hours      | Yes               | Yes                    |
| SharePoint Administrator  | 4 hours      | No                | Yes                    |

---

## Linux

### Ubuntu Server 24.04 - CIS Level 2

The primary Linux node is hardened to CIS Benchmark Level 2. Any deviation from Level 2 recommendations is documented in `linux/hardening/README.md` with justification.

| Section | Description                                            | Status  |
|---------|--------------------------------------------------------|---------|
| 1       | Initial Setup - Filesystem, Updates, Process Hardening | Planned |
| 2       | Services - Disable Unnecessary Services                | Planned |
| 3       | Network Configuration                                  | Planned |
| 4       | Host-Based Firewall (UFW)                              | Planned |
| 5       | Access, Authentication, and Authorization              | Planned |
| 6       | System Maintenance                                     | Planned |

The MySQL instance that backs the Assessment Engine and the architectural decision log runs on this node. Automated encrypted backups ship to Azure Blob Storage on a nightly schedule.

---

## M365 Configuration

| Area                       | Key Controls Applied                                                           | Status  |
|----------------------------|--------------------------------------------------------------------------------|---------|
| Exchange Online            | DMARC/DKIM/SPF, external email tagging, attachment blocking, 180-day audit log | Planned |
| Intune                     | Compliance policies (Windows + iOS), encryption, PIN, OS version minimum       | Planned |
| Defender for Office 365 P2 | Safe Links, Safe Attachments, Anti-Phishing, monthly Attack Simulation         | Planned |
| DLP                        | SSN, credit card, and credential policies across Exchange, SharePoint, Teams   | Planned |
| Information Protection     | Sensitivity labels with auto-labeling for financial and PII content            | Planned |

---

## Database

MySQL backend on the Ubuntu node tracking every architectural decision, configuration state, and change event across the environment.

| Table                      | Purpose                                                           |
|----------------------------|-------------------------------------------------------------------|
| `architectural_decisions`  | ADR log - what was built, why, and when                          |
| `configuration_states`     | Point-in-time snapshots of security control states               |
| `change_events`            | Audit log of every intentional environment change                |
| `resource_inventory`       | All Azure and M365 resources with tags and owners                |
| `compliance_findings`      | Assessment results linked to framework controls                  |

Schema definitions and seed data in `database/schema/`.

---

## Automation

### PowerShell

| Script                              | Purpose                                                           | Status  |
|-------------------------------------|-------------------------------------------------------------------|---------|
| `Get-FortressStatus.ps1`            | Collect Entra ID, Exchange, and Intune config state via Graph API | Planned |
| `Set-ConditionalAccessBaseline.ps1` | Idempotent deploy of CA policy set from JSON definitions          | Planned |
| `Invoke-PIMReview.ps1`              | Audit active PIM assignments, flag duration threshold violations  | Planned |
| `Export-ResourceInventory.ps1`      | Pull Azure resource inventory into MySQL via Az module            | Planned |

### Python

| Script                     | Purpose                                                               | Status  |
|----------------------------|-----------------------------------------------------------------------|---------|
| `fortress_report.py`       | Pull findings from MySQL and generate a Markdown status report        | Planned |
| `config_drift_detector.py` | Compare current state snapshots against baseline, surface differences | Planned |
| `resource_tagger.py`       | Audit Azure resource tags and flag non-compliant resources            | Planned |

---

## Architectural Decision Records

Decisions documented in `docs/decisions/` using a lightweight ADR format. Each record includes context, options considered, decision made, and consequences.

| ADR                                | Decision                                          |
|------------------------------------|---------------------------------------------------|
| ADR-001 - Hub-Spoke Topology       | Hub-and-spoke over flat VNet or Virtual WAN       |
| ADR-002 - PIM Eligible-Only        | No permanent admin assignments except break-glass |
| ADR-003 - MySQL on Ubuntu          | Self-managed MySQL over Azure SQL Database        |
| ADR-004 - CIS Level 2 over Level 1 | Level 2 for maximum hardening depth               |

---

## Build Status

| Component                         | Status      |
|-----------------------------------|-------------|
| Hub-Spoke VNet Topology           | In Progress |
| Entra ID Tenant Configuration     | In Progress |
| Conditional Access Baseline       | Planned     |
| PIM Configuration                 | Planned     |
| Ubuntu Server - CIS L2 Hardening  | Planned     |
| MySQL Schema                      | Planned     |
| M365 Security Baseline            | Planned     |
| Bicep IaC Templates               | Planned     |
| PowerShell Automation Scripts     | Planned     |
| Python Reporting Scripts          | Planned     |

---

## Related Projects

- [M365 Security Assessment Engine](https://github.com/devonbookerr) - PowerShell + Python tool that evaluates Entra ID tenant security posture and stores findings in MySQL
- [The Watchtower](https://github.com/devonbookerr) - Azure Sentinel detection lab with custom MITRE ATT&CK-mapped analytic rules

---

*Built by [Devon Booker](https://linkedin.com/in/devonbookerr) - Security Analyst at Arctic Wolf Networks*
