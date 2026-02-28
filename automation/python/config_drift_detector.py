#!/usr/bin/env python3
"""
The Fortress - Configuration Drift Detector
Compares the latest configuration snapshot in MySQL against the previous one.
Surfaces any controls that changed state between collection runs.
Status: Planned
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional

# TODO: pip install mysql-connector-python
# import mysql.connector


@dataclass
class DriftFinding:
    component: str
    control_id: str
    control_name: str
    previous_state: bool
    current_state: bool
    previous_snapshot: datetime
    current_snapshot: datetime

    @property
    def direction(self) -> str:
        """Returns 'degraded' if control went from compliant to non-compliant, 'improved' otherwise."""
        if self.previous_state and not self.current_state:
            return "degraded"
        return "improved"


@dataclass
class DriftReport:
    generated_at: datetime = field(default_factory=datetime.utcnow)
    findings: list[DriftFinding] = field(default_factory=list)

    @property
    def degraded(self) -> list[DriftFinding]:
        return [f for f in self.findings if f.direction == "degraded"]

    @property
    def improved(self) -> list[DriftFinding]:
        return [f for f in self.findings if f.direction == "improved"]

    def to_dict(self) -> dict:
        return {
            "generated_at": self.generated_at.isoformat(),
            "total_drift_findings": len(self.findings),
            "degraded_count": len(self.degraded),
            "improved_count": len(self.improved),
            "degraded": [
                {
                    "component": f.component,
                    "control_id": f.control_id,
                    "control_name": f.control_name,
                    "direction": f.direction,
                    "previous_snapshot": f.previous_snapshot.isoformat(),
                    "current_snapshot": f.current_snapshot.isoformat(),
                }
                for f in self.degraded
            ],
            "improved": [
                {
                    "component": f.component,
                    "control_id": f.control_id,
                    "control_name": f.control_name,
                    "direction": f.direction,
                }
                for f in self.improved
            ],
        }


def get_db_connection(host: str = "localhost", database: str = "fortress"):
    """Returns a MySQL connection. Caller is responsible for closing."""
    # TODO: Pull credentials from environment variables or Azure Key Vault
    # TODO: return mysql.connector.connect(
    #     host=host,
    #     database=database,
    #     user=os.environ["FORTRESS_DB_USER"],
    #     password=os.environ["FORTRESS_DB_PASS"],
    # )
    raise NotImplementedError("Database connection not yet implemented.")


def detect_drift(host: str = "localhost", database: str = "fortress") -> DriftReport:
    """
    Compares the latest and previous configuration snapshots from MySQL.
    Returns a DriftReport with all controls that changed compliance state.
    """
    report = DriftReport()

    # TODO: Execute compliance-dashboard.sql drift query
    # TODO: Map each result row to a DriftFinding
    # TODO: Append to report.findings

    return report


def main() -> int:
    report = detect_drift()

    print(json.dumps(report.to_dict(), indent=2))

    if report.degraded:
        print(f"\n[ALERT] {len(report.degraded)} control(s) degraded since last snapshot:", file=sys.stderr)
        for f in report.degraded:
            print(f"  - [{f.component}] {f.control_id}: {f.control_name}", file=sys.stderr)
        return 1

    print(f"\nNo degradation detected. {len(report.improved)} improvement(s) since last snapshot.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
