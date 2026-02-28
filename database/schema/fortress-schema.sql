-- The Fortress - MySQL Database Schema
-- Instance: Ubuntu Server 24.04 (DataSubnet: 10.1.2.x)
-- Database: fortress
-- Status: Planned

CREATE DATABASE IF NOT EXISTS fortress
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE fortress;

-- ── architectural_decisions ───────────────────────────────────────────────────
-- ADR log. One record per architectural decision. Never updated after insert -
-- superseded decisions get a new record with status = 'superseded' and a
-- reference to the superseding ADR.

CREATE TABLE IF NOT EXISTS architectural_decisions (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    adr_number          VARCHAR(10)     NOT NULL UNIQUE,        -- e.g. ADR-001
    title               VARCHAR(255)    NOT NULL,
    status              ENUM(
                            'proposed',
                            'accepted',
                            'rejected',
                            'deprecated',
                            'superseded'
                        )               NOT NULL DEFAULT 'proposed',
    context             TEXT            NOT NULL,               -- Why this decision was needed
    decision            TEXT            NOT NULL,               -- What was decided
    consequences        TEXT            NOT NULL,               -- What changes as a result
    component           VARCHAR(100)    NOT NULL,               -- e.g. 'networking', 'identity', 'linux'
    superseded_by       VARCHAR(10)     NULL,                   -- ADR number of superseding decision
    decided_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    decided_by          VARCHAR(100)    NOT NULL DEFAULT 'devon-booker',
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_status    (status),
    INDEX idx_component (component)
) COMMENT = 'Architectural Decision Records for The Fortress';


-- ── configuration_states ──────────────────────────────────────────────────────
-- Point-in-time snapshots of security control state across all components.
-- Collected by Get-FortressStatus.ps1 and Python equivalents.
-- Used for drift detection: compare latest snapshot against previous.

CREATE TABLE IF NOT EXISTS configuration_states (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    component       VARCHAR(100)    NOT NULL,               -- e.g. 'conditional-access', 'linux-cis', 'pim'
    control_id      VARCHAR(100)    NOT NULL,               -- e.g. 'CA001', 'CIS-5.2.1', 'PIM-GlobalAdmin'
    control_name    VARCHAR(255)    NOT NULL,
    expected_state  JSON            NOT NULL,               -- What the control should look like
    actual_state    JSON            NOT NULL,               -- What was observed
    is_compliant    TINYINT(1)      NOT NULL DEFAULT 0,
    drift_detected  TINYINT(1)      NOT NULL DEFAULT 0,
    collected_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    collector       VARCHAR(100)    NOT NULL,               -- e.g. 'Get-FortressStatus.ps1'

    INDEX idx_component_control (component, control_id),
    INDEX idx_collected_at      (collected_at),
    INDEX idx_is_compliant      (is_compliant)
) COMMENT = 'Point-in-time security control state snapshots';


-- ── change_events ─────────────────────────────────────────────────────────────
-- Audit log of every intentional change to the environment.
-- Inserted manually or by automation before making any configuration change.
-- Correlates with Sentinel alerts: if a change_event exists, the alert is expected.

CREATE TABLE IF NOT EXISTS change_events (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    change_type     ENUM(
                        'create',
                        'update',
                        'delete',
                        'enable',
                        'disable',
                        'deploy',
                        'rollback'
                    )               NOT NULL,
    component       VARCHAR(100)    NOT NULL,               -- e.g. 'conditional-access', 'bicep', 'linux'
    resource_name   VARCHAR(255)    NOT NULL,               -- e.g. 'CA001-AllUsers-RequireMFA'
    description     TEXT            NOT NULL,               -- Human-readable description of what changed
    reason          TEXT            NOT NULL,               -- Why this change was made
    changed_by      VARCHAR(100)    NOT NULL DEFAULT 'devon-booker',
    change_window   DATETIME        NULL,                   -- If part of a planned change window
    adr_reference   VARCHAR(10)     NULL,                   -- Links to architectural_decisions.adr_number
    changed_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reverted_at     DATETIME        NULL,                   -- Set if change was rolled back

    INDEX idx_component     (component),
    INDEX idx_changed_at    (changed_at),
    FOREIGN KEY (adr_reference)
        REFERENCES architectural_decisions(adr_number)
        ON DELETE SET NULL
) COMMENT = 'Audit log of all intentional environment changes';


-- ── resource_inventory ────────────────────────────────────────────────────────
-- Azure resource inventory collected by Export-ResourceInventory.ps1.
-- Upserted on each collection run. Used for tag compliance and asset tracking.

CREATE TABLE IF NOT EXISTS resource_inventory (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    resource_id         VARCHAR(500)    NOT NULL UNIQUE,        -- Azure resource ID (full path)
    resource_name       VARCHAR(255)    NOT NULL,
    resource_type       VARCHAR(255)    NOT NULL,               -- e.g. 'Microsoft.Network/virtualNetworks'
    resource_group      VARCHAR(100)    NOT NULL,
    location            VARCHAR(50)     NOT NULL,
    subscription_id     VARCHAR(36)     NOT NULL,
    tags                JSON            NULL,                   -- All tags as key-value JSON
    tag_environment     VARCHAR(50)     NULL,                   -- Extracted for easy querying
    tag_project         VARCHAR(50)     NULL,
    tag_owner           VARCHAR(100)    NULL,
    is_tag_compliant    TINYINT(1)      NOT NULL DEFAULT 0,     -- All required tags present
    first_seen          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_seen           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
                            ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_resource_type     (resource_type),
    INDEX idx_resource_group    (resource_group),
    INDEX idx_is_tag_compliant  (is_tag_compliant)
) COMMENT = 'Azure resource inventory with tag compliance state';


-- ── compliance_findings ───────────────────────────────────────────────────────
-- Security assessment findings from the Assessment Engine and manual audits.
-- One record per control per assessment run. Linked to resource_inventory where applicable.

CREATE TABLE IF NOT EXISTS compliance_findings (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    finding_id          VARCHAR(50)     NOT NULL,               -- e.g. 'ENTRA-001', 'CIS-5.2.1'
    title               VARCHAR(255)    NOT NULL,
    description         TEXT            NOT NULL,
    severity            ENUM(
                            'critical',
                            'high',
                            'medium',
                            'low',
                            'informational'
                        )               NOT NULL,
    status              ENUM(
                            'open',
                            'in_progress',
                            'resolved',
                            'accepted_risk',
                            'false_positive'
                        )               NOT NULL DEFAULT 'open',
    component           VARCHAR(100)    NOT NULL,
    framework           VARCHAR(50)     NULL,                   -- e.g. 'CIS', 'NIST', 'MITRE'
    control_reference   VARCHAR(100)    NULL,                   -- e.g. 'CIS-5.2.1', 'AC-2'
    resource_id         VARCHAR(500)    NULL,                   -- Links to resource_inventory
    affected_object     VARCHAR(500)    NULL,                   -- UPN, policy name, etc.
    remediation         TEXT            NULL,
    source              VARCHAR(100)    NOT NULL,               -- e.g. 'assessment-engine', 'manual'
    first_seen          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_seen           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
                            ON UPDATE CURRENT_TIMESTAMP,
    resolved_at         DATETIME        NULL,
    accepted_risk_note  TEXT            NULL,

    INDEX idx_severity          (severity),
    INDEX idx_status            (status),
    INDEX idx_component         (component),
    INDEX idx_finding_id        (finding_id),
    INDEX idx_first_seen        (first_seen)
) COMMENT = 'Security compliance findings from assessments and audits';


-- ── Seed Data: ADRs ──────────────────────────────────────────────────────────

INSERT INTO architectural_decisions
    (adr_number, title, status, context, decision, consequences, component)
VALUES
(
    'ADR-001',
    'Hub-and-Spoke VNet Topology',
    'accepted',
    'The Fortress needs a network architecture that provides centralized security controls while allowing workload isolation between production and development environments.',
    'Hub-and-spoke topology with a dedicated hub VNet hosting Azure Firewall. All spoke-to-spoke and spoke-to-internet traffic routes through the hub firewall via UDRs. No direct peering between spokes.',
    'All traffic flows through the hub firewall, enabling centralized logging and policy enforcement. Adds latency for spoke-to-spoke communication. Firewall becomes a single point of failure - mitigated by Azure Firewall SLA.',
    'networking'
),
(
    'ADR-002',
    'PIM Eligible-Only - No Permanent Admin Assignments',
    'accepted',
    'Admin accounts with permanent active privileged role assignments are a persistent attack surface. If an admin account is compromised, the attacker has indefinite privileged access.',
    'All privileged Entra ID roles are configured as eligible-only in PIM. No permanent active assignments except for one documented break-glass account with MFA and monitoring. All PIM activations require justification.',
    'Admins must activate roles through PIM before performing privileged actions. Activation events are logged and alertable. Break-glass account is excluded from all Conditional Access policies and requires manual monitoring.',
    'identity'
),
(
    'ADR-003',
    'Self-Managed MySQL on Ubuntu vs Azure SQL Database',
    'accepted',
    'The Fortress needs a relational database backend for the Assessment Engine and architectural decision log. Options are Azure SQL Database (managed PaaS) or self-managed MySQL on the Ubuntu node.',
    'Self-managed MySQL 8.0 on the Ubuntu Server node. Chosen to build operational depth in Linux database administration, cost optimization (no PaaS pricing), and to keep all data within the controlled environment.',
    'Requires manual backup configuration, patching, and performance tuning. Builds Linux and MySQL operational experience that maps to the 3-year skill architecture. Backup automation to Azure Blob Storage is a required compensating control.',
    'database'
);
