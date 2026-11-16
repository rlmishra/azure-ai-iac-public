# Phase 3 deployment and operations handoff

## Boundaries and prerequisites

No live Gravitee/Azure platform was configured or inspected in this task, and no live deployment was attempted. Phase 2 has implemented/local-tested source, not deployed Foundry models. Actual APIM server/gateway version, edition/license, plugin inventory, Management API URL, organizations/environments, Entra application contracts, gateway hosting and approved endpoint metadata remain required inputs. APIM 4.13.x is only a reference candidate. Obtain actual inventory before setting review flags; do not upgrade a platform on the strength of mock tests.

This Terraform manages APIM configuration through the official Automation API. It does not provision the gateway/control plane, commercial licenses, Azure VM, managed identity attachment, Entra directory applications, DNS, Private Link, certificates, Redis/counter store or collector. Configure management service-account permissions narrowly for the intended environment: APIs, plans, applications, subscriptions and shared policy groups. The provider documents that SPG GET returns steps only with environment SHARED_POLICY_GROUP UPDATE permission, so a read-only service account cannot necessarily refresh those resources. Do not default to organization-wide administrator access.

`gateways/` is the reference/test root. `gateways/dev`, `test`, `prod` are separate deployable roots/states. The Azure roots remain unchanged and own Azure resources/RBAC. Do not run two gateway roots against the same APIM resource HRIDs or state. Provide a protected remote backend (existing Azure backend or approved TFE) with a separate key/workspace such as enterprise-ai/dev/gravitee.tfstate and appropriate environment permissions. No remote-state data source reads the entire Azure state.

## Local validation on Windows

Use Terraform 1.17.2. New gateway locks pin gravitee-io/apim 1.2.0 with developer-signed Linux and Windows amd64 checksums. Azure roots retain AzureRM 5.13.0. From PowerShell at the repository root:

```powershell
terraform.exe fmt -check -recursive
./tests/Validate-Local.ps1        # Existing Azure regression checks
./tests/Validate-Gravitee.ps1     # Gateway checks + offline JSON schema checks
```

The Gravitee helper requires Python 3 and `jsonschema` installed through approved enterprise dependency tooling. It runs backend-disabled init, validation and mocked plan-only tests, then verifies rendered mock-plan policy JSON against Git-tree-pinned upstream schemas. For a single root:

```powershell
Set-Location gateways/dev
terraform.exe init -backend=false -input=false
terraform.exe validate
terraform.exe test
```

No real provider plan, service calls, subscriptions, API publication or policy updates are part of local validation. No apply-mode tests exist. Windows/PowerShell execution has not been performed on the Linux build host.

## Obtain approved non-secret Foundry metadata

After a **separately approved** Phase 2 development deployment, an authorized state reader can manually run:

```powershell
./tests/Export-FoundryMetadata.ps1 -EnvironmentPath ./environments/dev -OutputPath C:/ApprovedArtifacts/foundry-dev.json
```

The script selects account ID/OpenAI base endpoint and deployed model metadata; it does not copy tokens, keys or the full state and it explicitly marks the export NOT_APPROVED_BY_EXPORT. The script was not executed in this task. No deployed model output means a blocker, not permission to invent a deployment. Treat endpoint/identity/model metadata as classified configuration even when it contains no credentials.

An enterprise approver must check the account/deployment IDs, OpenAI base endpoint, explicit API version, model data-processing boundary, and authorization scopes, then supply an approval reference in `approved_backends`. Only classic public-Azure OpenAI chat/completions is supported. Phase 2 project endpoint maps, services.ai.azure.com unified inference, agent endpoints and MCP servers require distinct contracts and are rejected by this module. No general model endpoint or API-version translation is implied.

## Configure APIM safely

1. Choose one gateway environment root. Copy its safe terraform.tfvars.example or the fuller `modules/gravitee/examples/reviewed-inputs.tfvars.json.example` to a protected actual variable file. JSON tfvars files are gitignored. All examples are disabled, with publication, analytics and tracing off.
2. Supply the actual HTTPS Automation API URL, organization/environment IDs, reviewed matching 4.13.x server/gateway versions, edition/entitlement and exact required plugin/connector versions. Validate each installed policy's schema against the pinned generated configuration and its official compatibility matrix. Self-attestation flags record that external review; they cannot establish it automatically.
3. Configure service-account authentication outside Terraform through `APIM_SA_TOKEN` in the approved runner's secret store. The provider also supports APIM_CLOUD_TOKEN for approved Gravitee Cloud management; do not infer that the Azure VM IMDS data-plane topology works on a cloud-hosted gateway. Never paste tokens in chat or tfvars. Avoid debug logs that could reveal runtime/provider headers. No bearer_auth literal, API-key plan or secret input variable is provided.
4. Approve the Entra v2 tenant, exact audience, app role and token contract. Existing consumer application client IDs map to azp; Entra app registration, application roles, application permissions/admin consent and client authentication remain outside this stack. Each application's JWT subscription requires its own approved API association and explicit future expiry. Enforce organization-specific maximum lifetimes in release policy; the module requires expiry but does not invent that lifetime.
5. Confirm private gateway-to-Foundry routing and DNS forwarding, management-runner connectivity, host CA trust, TLS certificate/hostname validation, no unwanted backend redirects, streaming/body/timeout limits and a compatible distributed counter store. The approved public service hostname resolves to the Phase 2 private endpoint; keep the public hostname for correct TLS. No Azure NSG/RBAC/DNS changes are made by this root.
6. Review the VM identity topology and identity/RBAC prerequisites below. Confirm actual schema/licensing/operational readiness before setting deployment_enabled=true. Keep publish_apis=false for a stopped/unpublished/private draft configuration. Drafts create no subscriptions; applications may be explicitly configured without client secrets.
7. Only with actual approved development management/backend credentials may a real plan be generated. No such plan ran here. Review a complete plan/artifacts and obtain explicit approval before any apply. Publishing/starting APIs and creating subscriptions are separate live mutations, never a validation shortcut. No force-push, merge or deployment is authorized by the local test results.

## Backend identity reference and restrictions

This mode supports a gateway running on an isolated Azure VM with the specified user-assigned managed identity attached. Azure owners must give that identity the approved account-scoped Cognitive Services OpenAI User role, for example through the existing Phase 2 workload grant only when it really is the attached identity. The identity client ID is not the Entra object/principal ID used for Azure RBAC. Do not confuse them or assume that Terraform's application identity is automatically attached to any host.

The runtime HTTP Callout uses fixed Azure VM IMDS URL 169.254.169.254/metadata/identity/oauth2/token, API version 2018-02-01, Metadata:true and the Cognitive Services resource audience. It bypasses the system proxy and selects the explicit client ID. HTTP errors produce a generic 502; missing extracted tokens also stop the flow. The response's access_token exists only in request execution context. No consumer URL controls the callout and no acquired token is materialized as a Terraform value.

This is a composed reference flow using verified policy schema, **not** proof that native Azure managed identity is supported by every Gravitee connector. It does not support AKS federated workload identity, App Service identity endpoints, multicloud/Gravitee Cloud gateways or automatic token caching. Each allowed request makes a token call; test IMDS availability, host SSRF restrictions, concurrency/latency limits, failure behavior and rate caps before adoption. A more efficient/native cached token resource may be preferable, but requires its own verified schema/license/identity review. Do not relax general SSRF protection or expose IMDS to consumers merely to make this flow work.

Only POST `<context_path>chat/completions` is configured; the backend base `/openai/deployments/<approved-deployment>` combines with `/chat/completions`. Client query parameters are cleared before the approved api-version is set. Validate actual route joining, encoded traversal/normalization, unmatched routes, duplicate query values, header handling and negative operations on the target runtime before production publication. No policy fixture can prove those runtime semantics.

## Observability and privacy

Analytics, tracing, request/response header/body capture and OTel payload logs default off. Content/header/message capture and otel_logs cannot be enabled through the module. Optional analytics requires privacy review because IPs, client IDs and request metadata may identify people. Optional tracing also requires exporter/redaction review, analytics enabled, nonverbose tracing and full masking of attribute values. Collector configuration, host access/debug logs, trace names, request metadata/IP minimization, secret filters and retention remain external controls. Masked span attributes alone are not a guarantee that every host/exporter log is free of personal data.

Metrics/request counters are not LLM token accounting. Native AI token limiting, prompt injection/content moderation, PII guardrails, MCP/tool allowlists and safety evaluation are NOT implemented. No payload inspection or enforcement of tool fields in chat JSON is claimed. Gate enterprise AI workloads requiring those controls until an independently verified extension is approved. Azure model capacity and request-rate quotas are not per-consumer token/spend caps. SSE-aware usage accounting and model-specific guardrails need their own connector/plugin design.

## Live checks and Phase 4/5 handoff

All checks below are pending an explicitly approved development deployment and read/test authorization:

- Verify actual server/gateway versions, edition/entitlement, Automation API and required connector/policy schemas/permissions; inspect subscription status/manual validation semantics.
- Confirm private endpoint DNS/IP/routing/TLS; verify public Foundry data access remains denied. Confirm Management API remains on its approved access boundary.
- With approved test identities, check missing/invalid/expired JWT, wrong issuer/audience/role, missing azp, no subscription and cross-application/API attempts. Obtain tokens securely outside evidence artifacts.
- Check exact POST chat route, forbidden methods/MCP/agent paths, encoded-path and query tricks. Verify consumer credentials/cookies do not reach Foundry and the VM identity does.
- Simulate IMDS timeout/non-200/malformed/missing token and confirm no upstream request; verify no token appears in host, policy-error or collector logs.
- Exercise synchronous per-subscription counters across gateway nodes, rate/quota rejection and counter-store outage fail-closed behavior. Test LLM streaming/response timeouts separately; no token-budget claim is made.
- Emit redacted metadata canaries, inspect gateway/collector/Azure Monitor visibility and retention without logging prompts, completions, credentials or personal data.

AAP Phase 4 should perform these approved read/smoke checks and generate redacted evidence. It must not edit Terraform-owned resources. Azure DevOps Phase 5 owns PR checks, protected environments, approval gates, artifact retention and the choice of ONE Terraform executor (pipeline or TFE). Apply Azure first, approve its small metadata artifact, then plan gateway configuration from the independently approved platform inventory. AAP must not run a competing apply. No Phase 4/5 pipeline, runtime, gateway installation or ServiceNow integration is introduced here.
