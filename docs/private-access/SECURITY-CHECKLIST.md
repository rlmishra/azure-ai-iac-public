# Security review checklist

Source controls checked locally; all runtime items remain pending until an approved target exists.

- [x] Existing public-access/key/shared-key denial and trusted-bypass None preserved.
- [x] Existing endpoint service groups and centrally owned zone sets preserved; missing zone ownership rejected.
- [x] Independent workload vault/blob/telemetry permissions, all off by default; legacy behavior documented.
- [x] Existing role scope allowlist and separate Foundry inference/project grants preserved.
- [x] VM-only IMDS hosting selection and backend RBAC review required on gateway activation; no secret fallback.
- [x] No new provider/version/lock change, resource ownership migration, application secret value or runtime token output.
- [x] Gateway remains disabled/private/unpublished by default; no LLM token, guardrail or MCP claim.
- [ ] Actual inventory, licenses, plugins and Gravitee management authentication approved. MI-only management is unresolved.
- [ ] Private endpoints approved, service hostnames resolve privately from every caller, TLS/routing/NSG/UDR verified.
- [ ] VM identity attachment, exact UAMI selection, least-privilege scope and live SDK/inference tokens verified without logging tokens.
- [ ] Controlled Entra/JWKS, ARM, provider/package and vendor egress approved; no unsupported PE assumptions.
- [ ] Foundry model availability/entitlement, feature-specific project egress and dependent service support verified.
- [ ] Monitoring ingestion/query/DCR-DCE requirements, diagnostics, host log minimization and retention verified.
- [ ] State bootstrap/private backend/runner identity and container-level permissions reviewed separately; no circular bootstrap.
- [ ] Approved development plan and later deployment/recovery authorization obtained.

Pattern scanning is not organizational security certification or proof of live privacy. Do not certify end-to-end MI-only or all-private status while the dependency matrix contains unresolved paths.
