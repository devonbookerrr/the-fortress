# ADR-002: PIM Eligible-Only for All Privileged Roles

**Date:** 2026
**Status:** Accepted
**Decided by:** Devon Booker

## Context

Privileged role assignments need to follow least-privilege. Options range from permanent active assignments to PIM eligible-only.

## Options Considered

1. **Permanent active assignments** - Violates least-privilege. Standing admin is a major blast radius risk.
2. **Time-bound active assignments** - Better, but role is still active even when not needed.
3. **PIM eligible-only** - Role never active unless explicitly activated with justification, MFA, and optional approval.

## Decision

All privileged roles use PIM eligible-only. No permanent active privileged assignments except the documented break-glass account.

## Consequences

- Privileged access requires deliberate activation - reduces standing exposure
- Activation is logged and auditable
- Friction added to admin workflows (intentional - this is a security control)
- Break-glass account requires special handling - documented in `identity/pim/README.md`
