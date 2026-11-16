# Phase 3 capability and compatibility matrix

Verified 2026-11-16. Base d002f3e338dfd0073e11ba401ade7226fd4e6d9d. Official Registry selected gravitee-io/apim **1.2.0**, published 2026-11-03. Installed binary schema was exported; developer signing key **943FC12BEA201174** and Linux/Windows amd64 checksums are retained in the four new gateway lock files. Existing Azure/Terraform pins and locks are unchanged.

**Actual platform inventory was not supplied.** APIM 4.13.x is a reference candidate, not an observed installation or certified combination. Exact server/gateway patch, edition/Automation API entitlement, plugins, license and host settings require owner verification. Boolean confirmations in inputs record that external review; they are not an automatic license or compatibility discovery mechanism.

| Capability | Provider 1.2.0 evidence | Target server/gateway/plugin requirement | Implementation / limitation |
|---|---|---|---|
| V4 HTTP PROXY | apim_apiv4 typed attributes; pinned HTTP example | Actual Automation API and http-proxy connector compatible with 4.13.x | Implemented private/stopped by default; no hosting |
| Plans/auth | Nested plans.security JWT and configuration JSON | jwt plugin; Entra JWKS egress; exact issuer/audience/azp/roles contract | Implemented JWT plan + explicit claim guard; no keyless/API-key/DCR |
| Applications/subscriptions | apim_application settings.app; apim_subscription HRIDs and expiry | Existing Entra clients, app association/subscription behavior and management permissions | Implemented expiring JWT subscriptions on explicit publication; live acceptance/status checks pending |
| Rate/day quota | SPG steps + policy JSON | rate-limit/quota plugins and compatible distributed counter store | Synchronous, fail closed, per-plan/subscription request counts |
| Shared groups | apim_shared_policy_group and documented shared-policy-group-policy invocation with hrid | Shared group capability/entitlement; management service account also needs SPG UPDATE to read steps | Implemented; exact target plugin/feature confirmation mandatory |
| Backend Entra identity | V4 flow steps carry documented HTTP Callout/header configuration | policy-http-callout, policy-interrupt, transform-headers; Azure VM IMDS/UAMI/account RBAC | Limited secret-free runtime IMDS reference; no cache, native connector or general WIF claim |
| Fixed routes/query | Flow selectors and match_required; transform-queryparams schema | Exact HTTP route/policy behavior, URI normalization, TLS and no unwanted redirects | Explicit classic Azure OpenAI chat/completions only; runtime tests mandatory |
| Analytics/logging | analytics.logging / otel_logs typed schema | Host reporter controls and retention; metadata privacy approval | Disabled by default; payload/header logging always off |
| OpenTelemetry | analytics.tracing/redaction typed schema | Actual runtime support, collector/exporter and redaction/privacy review | Opt-in nonverbose full-value masking; no host exporter provisioned |
| LLM token limits | Opaque flow JSON can carry plugin configuration; no evidence of installed token-policy semantics | Exact AI plugin schemas, edition/license, token measurement and streaming support unknown | NOT implemented. Request counts and Azure deployment capacity are not token budgets |
| AI guardrails | Opaque flow configuration is not proof of enforcement | Actual moderation/PII/prompt/response policy plugin schemas, license and safety design unknown | NOT implemented; no enterprise AI guardrail claim |
| MCP/tool access | Provider exposes apim_mcp_proxy and apim_catalog_mcp_server | Approved MCP server/protocol, plugins, authorization and edition unknown | Surfaces verified but intentionally not configured; chat route does not expose MCP |
| Native LLM/unified Foundry APIs | Provider V4 surfaces do not imply a universal backend contract | Connector-specific schemas/auth/model semantics and license unknown | Excluded, not silently treated as OpenAI chat |

## Primary evidence

- Registry: https://registry.terraform.io/providers/gravitee-io/apim/1.2.0
- Pinned provider index/auth: https://github.com/gravitee-io/terraform-provider-apim/blob/v1.2.0/docs/index.md
- Setup/Automation API: https://github.com/gravitee-io/terraform-provider-apim/blob/v1.2.0/docs/guides/setup.md
- V4 resource: https://github.com/gravitee-io/terraform-provider-apim/blob/v1.2.0/docs/resources/apiv4.md
- Application: https://github.com/gravitee-io/terraform-provider-apim/blob/v1.2.0/docs/resources/application.md
- Subscription: https://github.com/gravitee-io/terraform-provider-apim/blob/v1.2.0/docs/resources/subscription.md
- Shared group: https://github.com/gravitee-io/terraform-provider-apim/blob/v1.2.0/docs/resources/shared_policy_group.md
- Invocation JSON: https://github.com/gravitee-io/terraform-provider-apim/blob/v1.2.0/examples/use-cases/v4api-shared_policy_group/proxy-api-spg.tf
- Microsoft VM identity token protocol: https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/how-to-use-vm-token
- Microsoft Cognitive Services resource audience: https://learn.microsoft.com/azure/ai-services/authentication
- Microsoft IMDS restrictions: https://learn.microsoft.com/azure/virtual-machines/instance-metadata-service
- Phase 2 outputs and Azure endpoint evidence: ../phase2/CAPABILITIES.md and ../../modules/foundry/outputs.tf

`provider-schema.json` is the installed provider/schema excerpt for the four implemented resources, including nested analytics/plans/listeners/flows. Seven upstream policy JSON schemas are byte-preserved under `modules/gravitee/schemas/`; PROVENANCE.json records immutable source Git-tree URLs and SHA-256 hashes. The HTTP endpoint target JSON and shared-policy invocation come from the pinned provider examples. No arbitrary operator JSON is allowed to bypass this small supported policy set.

Official JWT README's compatibility matrix lists 8.x for APIM 4.12+ / Java 21, 7.x for 4.9–4.11; HTTP Callout README lists 6.x for 4.11+, 5.x for 4.6–4.10. Those are documented family boundaries, not evidence that a particular installed patch matches every captured schema. Validate the actual selected versions against the pinned configuration before setting policy_schema_compatibility_confirmed. Test fixtures deliberately contain synthetic plugin versions and cannot be used as a production inventory.

The hosted Gravitee documentation site returned HTTP 403 to research requests. Provider reference docs/examples and policy schemas/READMEs were retrieved from official GitHub repositories instead. No live Management API, gateway or license was queried; there is no observation of current commercial entitlement or universal minimum supported APIM version for provider 1.2.0. Do not interpret the candidate baseline as an upgrade instruction. Unsupported features need a separate reviewed provider/plugin/API design, not Terraform provisioners or generic lifecycle HTTP calls.

The module rejects known incompatible JWT/HTTP Callout major families for this reference: JWT must be 8.x and Callout 6.x, matching the retrieved compatibility matrices. Other plugin versions and exact patch/schema/edition compatibility remain external review requirements; these family checks are not certification.
