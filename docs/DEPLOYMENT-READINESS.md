# Phase 1 deployment-readiness checklist

Local validation is complete. Cloud deployment remains unapproved and untested. Resolve and record the following with enterprise owners before a development plan/apply.

- [x] Inspect initial workspace and record assumptions before source generation.
- [x] Pin CLI/provider versions and retain signed provider checksum locks for Windows/Linux amd64.
- [x] Verify executable resources against the installed AzureRM schema.
- [x] Pass format, init, validation and mocked tests on reference/dev/test/prod roots.
- [x] Disable public service access, shared keys/local authentication and default subnet outbound access.
- [x] Enforce explicit NSG rules, Private Link DNS links, required tags and regional input allowlist.
- [x] Default workload RBAC grants to off; reject broad scopes and privileged roles in the identity module.
- [x] Configure purge protection, soft deletion, blob versioning/retention and infrastructure encryption.
- [ ] Approve actual subscription, tenant, regions and data residency. Validate selected storage replication availability.
- [ ] Check global storage/Key Vault name availability, subscription quota, region capabilities and landing-zone constraints.
- [ ] Register required Azure resource providers through the landing-zone administrator.
- [ ] Allocate nonoverlapping VNet/subnet CIDRs; confirm hub routes and explicit trusted private-runner/admin source ranges.
- [ ] Establish hub DNS forwarding and ownership of the six private zones. Review AMPLS shared-DNS effects on existing monitoring clients.
- [ ] Bootstrap external private remote state; configure unique environment keys, Entra access, locking, versioning, recovery and artifact retention.
- [ ] Approve the executor's management and narrowly scoped role-assignment authority. Configure OIDC or approved development CLI authentication externally.
- [ ] Supply existing enterprise deny/audit policy or initiative IDs and parameters, or demonstrate inherited policies. Review assignments before first plan; empty input is not compliance.
- [ ] Resolve DINE/Modify remediation ownership, policy exemptions, central logging and encryption/CMK requirements with landing-zone owners.
- [ ] Define alert routing, health thresholds, cost/budget alerts, VNet flow logs and subscription activity-log export ownership.
- [ ] Set application SDK Entra authentication, telemetry redaction and data retention. Configure workload identity attachment in the application phase.
- [ ] Run security scanner/TFLint and organizational policy checks through the later CI/CD phase; review findings rather than treating schema tests as security certification.
- [ ] Review a real development plan with approved credentials/state. Obtain explicit approval before any apply.
- [ ] After approved deployment, verify DNS resolves service FQDNs to expected endpoint IPs from the private runner; confirm endpoint connection states are Approved.
- [ ] Check Key Vault/blob access with an authorized identity, confirm unauthorized identities are denied, and confirm public data-plane access fails.
- [ ] Query actual diagnostic categories and confirm diagnostic settings match; emit an Entra-authenticated telemetry canary and find it through private Log Analytics access.
- [ ] Test Key Vault secret recovery, blob version restore and state restore; record owners, evidence and actual recovery times.
- [ ] Approve RPO/RTO and second-region architecture; GZRS alone is not end-to-end DR. Confirm data replication and failover restrictions.
- [ ] Complete Phase 2 Foundry schema/model/private-connectivity verification before implementing Foundry workloads.

Apply authorization is separate from this checklist. No checkbox here grants permission to provision infrastructure.
