# ADR-001: Hub-and-Spoke VNet Topology

**Date:** 2026
**Status:** Accepted
**Decided by:** Devon Booker

## Context

The Fortress requires a network architecture supporting centralized security controls, east-west traffic inspection, and clean environment separation between production and development workloads.

## Options Considered

1. **Flat single VNet** - Simple, but no traffic inspection between workloads and no environment separation.
2. **Hub-and-spoke** - Centralized services in hub (firewall, DNS, gateway). All inter-spoke traffic through hub.
3. **Azure Virtual WAN** - Over-engineered for current scope and adds unnecessary cost.

## Decision

Hub-and-spoke. Hub VNet hosts Azure Firewall, DNS Resolver, and VPN Gateway. Two spokes: production and development. All spoke-to-spoke traffic routed through hub firewall via UDRs.

## Consequences

- East-west traffic inspected by Azure Firewall - improves visibility and control
- Additional cost for Azure Firewall (mitigated by Basic SKU in lab context)
- More complex deployment - addressed by Bicep IaC templates
- Scales cleanly if additional spokes needed (DMZ, partner, etc.)
