# ADR-003: MySQL on Ubuntu Server vs Azure SQL Database

**Date:** 2026
**Status:** Accepted
**Decided by:** Devon Booker

## Context

The Fortress needs a relational database for the decision log, configuration state tracking, and Assessment Engine findings.

## Options Considered

1. **Azure SQL Database (managed)** - Fully managed, highly available, built-in security features. Higher cost. Less operational experience.
2. **MySQL on Ubuntu Server** - Self-managed. Lower cost. Builds Linux and MySQL administration skills directly.

## Decision

MySQL 8.0 on the Ubuntu Server node.

## Consequences

- Lower cost (no Azure SQL compute)
- Hands-on MySQL installation, hardening, backup, and maintenance experience
- Single point of failure (acceptable for lab - documented)
- Requires backup strategy - automated dump to Azure Blob Storage via `linux/automation/backup-mysql.sh`
