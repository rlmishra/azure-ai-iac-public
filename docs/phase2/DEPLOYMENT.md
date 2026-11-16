# Phase 2 configuration and deployment handoff

No cloud deployment has been performed. Use this source only after approved development credentials, backend access and enterprise inputs are supplied. A mock test is not deployment approval.

## Windows local validation

Use Terraform 1.17.2 and the committed AzureRM 5.13.0 locks (unchanged from Phase 1, Windows/Linux amd64 checksums included). From the repository root in PowerShell:

```powershell
terraform.exe fmt -check -recursive
terraform.exe init -backend=false -input=false
terraform.exe validate
terraform.exe test
./tests/Validate-Local.ps1
```

The helper checks all four roots, including existing Phase 1 regressions and new Foundry integration tests. Plan-only module tests are in `tests/foundry-module.tftest.hcl`. No Azure credentials are needed for mocks. Windows execution of this helper has not been performed on the Linux build host.

## Opt into Foundry

Environment `terraform.tfvars.example` files retain `foundry = null`. This preserves Phase 1 resources and addresses by default. To prepare an enabled environment:

1. Copy the environment's foundation example to `terraform.tfvars`; supply actual approved foundation inputs.
2. Copy its `foundry.tfvars.example` to `foundry.tfvars`. Choose approved, globally unique account/subdomain names and project names. Keep all model maps empty and grants off until reviewed.
3. Configure the **existing** remote backend as described in the root README. Use a private authorized runner and Entra/WIF authentication; do not place tokens in variable files.
4. With approved development credentials/state, a reviewed plan may be generated using the overlay explicitly:

```powershell
Set-Location environments/dev
terraform.exe init -backend-config=backend.hcl
terraform.exe plan -input=false -var-file=terraform.tfvars -var-file=foundry.tfvars -out=dev-foundry.tfplan
```

The order of var files is intentional: `foundry.tfvars` overrides the disabled foundation example. Do not deploy both the reference root and an environment root into the same resources. Protect plan/state files and never commit them. **No apply or destroy is authorized.**

To deploy models later, obtain the organization's exact catalog approvals, validate live account/region model listings and capacity, add corresponding `approved_models` and `deployments` entries, then set `enable_model_deployments = true`. Every request must reference an approved catalog key, region, SKU and per-deployment capacity. Versions never default or auto-upgrade. The model/version strings in tests are synthetic approval fixtures; do not use them as recommendations or evidence of present availability.

## Azure prerequisites and checks before deployment

- Register Microsoft.CognitiveServices through landing-zone administration, in addition to Phase 1 providers. Ensure the executor can manage accounts/projects/deployments, private endpoints, diagnostic settings and explicitly approved role assignments at the required resource/RG scopes. No subscription-wide application grants are needed.
- Verify AIServices project-management support in the approved public-Azure region, globally unique custom subdomain, service policy acceptance, quota, model entitlement and deployment SKU. An approved account region does not imply an approved global model-processing boundary.
- Approve the landing-zone policy/initiative assignments and inherited policies, CMK requirements, diagnostic retention and telemetry content controls. No blanket compliance claim is made.
- Provide private runner/admin routing and DNS forwarding for `cognitiveservices.azure.com`, `openai.azure.com` and `services.ai.azure.com`, in addition to the foundation namespaces. The networking module owns one new `account` private endpoint and three linked zones. Existing HTTPS endpoint-subnet rules already cover it; no Internet or service-tag egress is opened.
- Import/adapt centrally managed zones instead of creating duplicate owners. Confirm shared DNS and AMPLS implications with the landing-zone team. Private Link secures inbound client connectivity; restricted account egress does not automatically provide network-injected agent access to vault/storage/tools.
- Review account/project `prevent_destroy` and disabled provider purge behavior. Removing resource configuration removes Terraform lifecycle protection; neither protection is a backup or recovery plan.

## Identity, observability and application readiness

`foundry_grant_workload_openai_access = true` grants the existing Phase 1 application identity OpenAI User at the new account, without changing the foundation identity module's allowlist. This is an explicit account-wide OpenAI inference grant. Attach the identity to application compute and use Entra-enabled SDKs; no compute is provisioned here. Request an appropriate Azure AI token audience through the supported SDK (Cognitive Services commonly uses `https://cognitiveservices.azure.com/.default`); validate the exact endpoint/API contract for each application.

Microsoft's architecture guidance assigns Foundry User to each project managed identity at the account scope for runtime features that use account models. This is controlled by `grant_account_access`, deliberately false until approved. Explicit project `users` grants are project scoped. Default project creation alone does not authorize those runtime operations. Optional vault/blob reads do not configure agent connections or network access. The service may require additional feature-specific identities/roles beyond the scope of this phase.

Foundry account diagnostics reuse `modules/monitoring` and the existing workspace: `Audit` logs and `AllMetrics`. `RequestResponse`, `Trace`, and broad allLogs are not enabled. Public Azure documentation lists Audit for Cognitive Services accounts, but actual supported categories and resource-specific behavior must be confirmed after approved deployment. Inspect Audit content and retention before production; do not assume any log category is free of identifiers or sensitive metadata. Application Insights remains the application SDK's responsibility; no unsupported automatic account-to-App-Insights property is invented.

After a separately approved development deployment:

1. Query private endpoint connection approval and confirm expected private IPs for account, OpenAI and project endpoint hosts from the private runner. Confirm public data-plane access fails.
2. Verify allowed Entra inference works and unassigned identities/API keys cannot authenticate. Validate project scope boundaries and cross-project isolation with appropriate test identities.
3. List supported diagnostic categories on the actual account (`az monitor diagnostic-settings categories list --resource <approved-account-id>`), confirm settings, and verify redacted test telemetry arrives through private Azure Monitor access. These read/SDK checks need deployed resources and were not run locally.
4. Verify model version, capacity, processing boundary, quotas, retirement behavior and cost alerts. Capture evidence for AAP in Phase 4.

## Scope, recovery and handoff

No Gravitee APIs, gateway policies, agent hosts/tools, Search, standard-agent state resources, provisioned capacity purchasing, custom RAI policies, prompt/response retention policies, alert action groups or multiregion failover are deployed. The optional `rai_policy_name` must reference a separately reviewed existing policy; the service's default content filtering is not a custom enterprise guardrail implementation.

Azure-managed encryption is provided by the service. CMK requirements, customer-managed key recovery, application/agent state retention, backup and recovery exercises must be approved separately. Azure may retain abuse-monitoring information under service terms independently of diagnostics; confirm current retention/data-processing commitments with your governance team. Neither private networking nor omitting request/response diagnostics changes those service terms.

A second region needs a separate account/project/network/state design, explicit region-specific model capacity/versions, identity grants and application routing with approved RPO/RTO and recovery exercises. No application DR is implemented by this phase.

Phase 3 receives non-secret `foundry` output metadata. Preserve project endpoint maps verbatim and select each API contract deliberately: an OpenAI-compatible base endpoint is not a universal Foundry inference or project API endpoint. Gateway consumer auth, backend token acquisition, token accounting, MCP and guardrails are Phase 3 work.
