-- compliance-dashboard.sql
-- Reference queries for the Fortress compliance dashboard and reporting.
-- All queries target the fortress database.

USE fortress;

-- ── Open findings by severity ─────────────────────────────────────────────────
SELECT
    severity,
    COUNT(*) AS finding_count,
    GROUP_CONCAT(DISTINCT component ORDER BY component SEPARATOR ', ') AS affected_components
FROM compliance_findings
WHERE status = 'open'
GROUP BY severity
ORDER BY FIELD(severity, 'critical', 'high', 'medium', 'low', 'informational');


-- ── Drift detection: controls that changed state in the last 24 hours ─────────
SELECT
    cs1.component,
    cs1.control_id,
    cs1.control_name,
    cs1.is_compliant AS current_state,
    cs2.is_compliant AS previous_state,
    cs1.collected_at AS current_snapshot,
    cs2.collected_at AS previous_snapshot
FROM configuration_states cs1
JOIN configuration_states cs2
    ON cs1.component = cs2.component
    AND cs1.control_id = cs2.control_id
    AND cs2.collected_at = (
        SELECT MAX(collected_at)
        FROM configuration_states
        WHERE component = cs1.component
          AND control_id = cs1.control_id
          AND collected_at < cs1.collected_at
    )
WHERE cs1.collected_at = (
        SELECT MAX(collected_at)
        FROM configuration_states
        WHERE component = cs1.component
          AND control_id = cs1.control_id
    )
  AND cs1.is_compliant != cs2.is_compliant
ORDER BY cs1.component, cs1.control_id;


-- ── Resources missing required tags ──────────────────────────────────────────
SELECT
    resource_name,
    resource_type,
    resource_group,
    CASE WHEN tag_environment IS NULL THEN 'MISSING' ELSE tag_environment END AS environment_tag,
    CASE WHEN tag_project     IS NULL THEN 'MISSING' ELSE tag_project     END AS project_tag,
    CASE WHEN tag_owner       IS NULL THEN 'MISSING' ELSE tag_owner       END AS owner_tag
FROM resource_inventory
WHERE is_tag_compliant = 0
ORDER BY resource_group, resource_name;


-- ── Recent change events (last 7 days) ────────────────────────────────────────
SELECT
    changed_at,
    change_type,
    component,
    resource_name,
    changed_by,
    LEFT(description, 100) AS description_preview,
    adr_reference
FROM change_events
WHERE changed_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
ORDER BY changed_at DESC;


-- ── ADR summary ───────────────────────────────────────────────────────────────
SELECT
    adr_number,
    title,
    status,
    component,
    decided_at
FROM architectural_decisions
ORDER BY adr_number;


-- ── Findings resolved in the last 30 days ────────────────────────────────────
SELECT
    finding_id,
    title,
    severity,
    component,
    resolved_at,
    DATEDIFF(resolved_at, first_seen) AS days_to_resolve
FROM compliance_findings
WHERE status = 'resolved'
  AND resolved_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
ORDER BY resolved_at DESC;
