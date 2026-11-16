# Phase 2 security and readiness

## Implemented and locally checked

- [x] Current account/project architecture, official pinned AzureRM resources; no AzAPI or provider upgrade.
- [x] Original Phase 1 implementation/resource addresses preserved; Foundry null by default.
- [x] Private account, project management enabled, explicit subdomain and system identities.
- [x] Local/API-key auth disabled; outbound restrictions, deny ACL and no trusted-service bypass.
- [x] One account Private Link endpoint, three linked private zones through the existing networking owner.
- [x] Explicit per-project/account data grants and stable role GUIDs; no Owner/Contributor or subscription-wide grants.
- [x] Catalog-based model/version/region/SKU/capacity approvals; separate activation, no default model, NoAutoUpgrade.
- [x] Audit/metrics diagnostics reuse existing Log Analytics; no RequestResponse/Trace/allLogs enabled.
- [x] No secret inputs/outputs; account/project prevent_destroy and disabled cognitive-account purge-on-destroy.
- [x] Source/plan-only mocked tests and unchanged Phase 1 regressions; no cloud writes.

## Organizational and runtime prerequisites

- [ ] Approve real inputs, account/subdomain uniqueness, public-Azure region support and Microsoft.CognitiveServices registration.
- [ ] Confirm data-processing boundaries for selected regional/global/data-zone/batch SKU; verify service retention/abuse-monitoring terms and privacy requirements.
- [ ] Verify model format/name/version availability, capacity units, aggregate quotas, entitlement, marketplace terms and retirement schedule. Approvals are not availability guarantees.
- [ ] Establish private runner/admin routing and service namespace DNS forwarding. Reconcile central private-zone ownership; verify all endpoint connection states and private IPs after approved deployment.
- [ ] Approve required Foundry User project/account grants, OpenAI inference scope, project-user access and optional data reads. Validate permission propagation and isolation with live test identities.
- [ ] Configure application compute identity attachment and correct endpoint/API/token audience per model; no universal SDK contract is assumed.
- [ ] Confirm Audit/AllMetrics support on the actual account, redact/review emitted metadata, apply approved retention and verify telemetry canaries through private monitoring.
- [ ] Supply/apply enterprise policy IDs or verify inherited controls; assess CMK, key recovery, network egress and feature-specific standard-agent requirements.
- [ ] Configure protected remote backend, OIDC/approved CLI identity, narrow executor privileges, plan/evidence retention, alerting and budgets.
- [ ] Review a real development plan; obtain explicit approval before any apply. No checklist item grants that permission.
- [ ] Test restore/recovery, then approve separate-region capacity, state/secret replication and routing with measurable RPO/RTO. No end-to-end DR is implemented here.
- [ ] Validate advanced agents, connections, tools/MCP and gateway controls in their relevant future phases; no such runtime readiness is claimed.
