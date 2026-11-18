# Phase 3 readiness checklist

## Implemented/local checks

- [x] Official pinned APIM provider/schema, developer-signed locks for Linux/Windows amd64.
- [x] Existing Azure source/pins/locks unchanged; separate gateway roots/state boundary.
- [x] No gateway resources by default; private stopped/unpublished drafts; publication explicit.
- [x] JWT-only Entra v2 client authentication, app association, issuer/audience/role/exp/azp guards and explicit expiring subscriptions; no API-key/DCR secrets.
- [x] Approved classic OpenAI deployment metadata only; exact POST operation and pinned query API version; no arbitrary backend or policy JSON input.
- [x] Shared synchronous request limits/quota, fail closed on internal errors; no false LLM token-budget claim.
- [x] Consumer credentials stripped; fixed-host runtime VM IMDS token acquisition and missing-token failure guard; no runtime token in Terraform data.
- [x] Analytics/tracing off by default; request/response headers/content and OTel payload logs always disabled.
- [x] Git-tree-pinned upstream policy schemas with provenance/license and offline generated-plan contract checks.

## Required before live use (not completed by this task)

- [ ] Inventory actual server/gateway patch/edition, compatible plugin/connector versions, license and Automation API entitlement; no installed target was provided.
- [ ] Approve narrowly scoped management credentials/permissions and protected distinct environment state. Never store tokens in configuration/chat/logs.
- [ ] Deploy Phase 2 separately with approval; verify real endpoint/model/version/deployment metadata, quota and data-processing policies. Exported metadata is not approval.
- [ ] Establish private routes, DNS, CA trust, TLS/hostname checks, redirect controls, timeouts/body limits and distributed counter store.
- [ ] Confirm isolated Azure VM hosting/UAMI attachment, object-vs-client IDs, account-scoped RBAC, IMDS access/SSRF controls and viable per-request token-call throughput. Other hosting/WIF topologies are unsupported.
- [ ] Verify JWT/app-role/subscription/expiry/cross-API enforcement, exact route normalization, forbidden paths/query values, credential separation, and token failure behavior on the real runtime.
- [ ] Validate distributed rate/quota/counter-outage behavior; define separate verified token/spend/AI safety controls if required. Request counts are not token limits.
- [ ] Configure host/collector telemetry, metadata/IP minimization, redaction, retention and redacted canaries. Verify tokens/prompts/responses/PII are absent from all logs, not just API logging settings.
- [ ] Independently verify any future guardrail/MCP/native AI policy/schema/licensing; no such enforcement exists in this HTTP baseline.
- [ ] Review a real development plan and obtain separate approval before creating configurations, subscriptions, publishing APIs or changing policies. No live mutations were performed here.
- [ ] Define rollback/recovery, evidence ownership and a single Azure DevOps/TFE execution owner; AAP remains validation/evidence only.
