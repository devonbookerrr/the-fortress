# Automation - Python

Python scripts for reporting and drift detection in The Fortress.

## Scripts

| Script | Purpose | Status |
|---|---|---|
| `fortress_report.py` | Pull findings from MySQL, generate Markdown status report | Planned |
| `config_drift_detector.py` | Compare state snapshots against baseline, surface differences | Planned |
| `resource_tagger.py` | Audit Azure resource tags, flag non-compliant via Azure SDK | Planned |

## Dependencies

```
azure-identity
azure-mgmt-resource
mysql-connector-python
jinja2
```

## Standards

- `DefaultAzureCredential` for all Azure auth
- Type hints on all functions
- `logging` module (not print statements)

## Status: Planned
