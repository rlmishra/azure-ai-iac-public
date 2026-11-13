# Azure enterprise AI infrastructure — Phase 1

Production-oriented foundation source, **locally validated; not deployed**. The current deliverable implements Phase 1. Foundry, Gravitee, AAP and Azure DevOps implementation remain in the subsequent phases. No Terraform apply, destroy, real Azure plan, production-secret access or cloud mutation was performed.

Read [assumptions](docs/ASSUMPTIONS.md), [architecture](ARCHITECTURE.md), [provider verification](docs/PROVIDER-CAPABILITIES.md), [readiness checklist](docs/DEPLOYMENT-READINESS.md) and [validation report](docs/VALIDATION.md) before planning a deployment.

## Contents

- `modules/networking`: VNet, two subnets, NSGs and explicit rules, private DNS and service endpoints through Private Link.
- `modules/identity`: one user-assigned managed identity and explicit resource-scoped Entra role assignments.
- `modules/security`: private RBAC Key Vault, private keyless blob storage, retention controls and optional existing policy/initiative assignments.
- `modules/monitoring`: private Log Analytics, workspace-based Application Insights, Azure Monitor Private Link Scope and diagnostic settings.
- `environments/dev`, `test`, `prod`: separate deployment roots, version locks, example variables and mocked tests. Never share their state.
- `tests`: composition, negative input, network isolation and least-privilege tests.
- `modules/foundry`, `modules/gravitee`, `ansible` and `pipelines`: explicitly pending later phases, with no fictional executable resources.

The repository root is a reference composition and test entry point. Deploy from exactly one environment root per environment; do not deploy the root and an environment root to the same resources. Environment roots compose the same reusable modules. Keep composition changes synchronized; the supplied tests exercise each root.

## Windows 11 / VS Code

Install Terraform **1.17.2** from HashiCorp, Git and Azure CLI using approved enterprise distribution. Open this folder in VS Code and use its PowerShell terminal. AzureRM is pinned to **5.13.0**; lock files include authenticated Linux and Windows amd64 checksums. No Azure credentials are needed for these commands:

```powershell
terraform.exe version
terraform.exe fmt -check -recursive
terraform.exe init -backend=false -input=false
terraform.exe validate
terraform.exe test

# Run the same checks for each deployment root (script stops on errors):
./tests/Validate-Local.ps1
```

`init -backend=false` intentionally avoids remote state for local tests. `terraform init` without that flag also works while the optional backend configuration has not been enabled. Provider downloads require access to registry.terraform.io and releases.hashicorp.com. Mocked `terraform test` runs plan commands inside the test harness; it does not authenticate to Azure or create infrastructure. There are no apply-mode tests.

## Prepare a development plan

1. Confirm the readiness checklist, private runner connectivity, approved subscription/region, nonoverlapping IP allocations and globally unique names.
2. In `environments/dev`, copy `terraform.tfvars.example` to `terraform.tfvars` and replace all illustrative values. The prod root enforces `environment = "prod"`; test and dev similarly enforce their identities.
3. Use an **existing, separately bootstrapped** remote state account/container. Copy `docs/backend.tf.example` to `environments/dev/backend.tf` and create `backend.hcl` from `docs/backend.hcl.example`. Use separate keys and preferably separate backend permissions/accounts for each environment. Never store secrets in either file.
4. Authenticate with an approved Azure CLI development login or workload identity federation. Provider authentication is external to these modules. For OIDC, configure `ARM_USE_OIDC`, `ARM_CLIENT_ID`, `ARM_TENANT_ID` and `ARM_SUBSCRIPTION_ID` in the approved runner; do not paste tokens into tfvars. Token delivery depends on the runner and is configured in Phase 5.
5. Only when development credentials and state access are approved and available, run:

```powershell
Set-Location environments/dev
terraform.exe init -backend-config=backend.hcl
terraform.exe validate
terraform.exe test
terraform.exe plan -input=false -out=dev.tfplan
```

Protect plans, state and evidence as confidential artifacts. Inspect the complete plan, inherited policy results, costs and role grants. **Apply requires explicit approval and is outside this deliverable.** Do not use `-target` to work around dependency failures.

## Important operation details

- Public access is disabled for Key Vault, storage and monitoring; CI, AAP and administrators need private DNS resolution and network access. `trusted_prefixes` grants HTTPS in NSGs but does not create routing, peering or an administrative path.
- With custom `dns_servers`, the landing zone must forward the Azure service public namespaces into Azure DNS Private Resolver or a DNS forwarder that can resolve the linked private zones. Linking zones alone is insufficient.
- `grant_workload_data_access` defaults to false. Opt-in grants secrets read, blob read and Application Insights telemetry publishing, each at its resource scope. It does not attach the identity to an application host; Phase 2/application deployment must do that and configure Entra-enabled SDKs.
- Key Vault secrets and storage containers are deliberately not created. Avoid storing secret values in Terraform state. Storage Blob service retention is configured through AzureRM's ARM client in this pinned version, without bootstrapping a public data endpoint.
- Azure Policy assignments accept existing deny/audit definitions or initiatives with JSON-encoded parameters. Empty defaults **do not establish landing-zone compliance**. DeployIfNotExists/Modify remediation identities, policy exemptions and subscription management remain with the landing-zone owner.
- Key Vault and storage have `prevent_destroy`; planned replacement/deletion fails while these resource blocks remain. Removing a block removes that protection. Key Vault also retains purge protection and soft deletion. These controls do not replace backups and recovery tests.
- Regional availability, quota, diagnostic categories and organization policy are runtime checks. A passing mocked plan cannot establish any of them.

## Subsequent phases

Phase 2 must verify current Foundry account/project/model schemas and Private Link support before adding resources; use AzAPI only for a proven AzureRM gap. Phase 3 must install and inspect the official `gravitee-io/apim` schema and document edition/plugin/version dependencies before configuring gateway resources. Phase 4 assigns AAP post-deployment validation/evidence ownership. Phase 5 assigns Azure DevOps validation/approvals ownership and chooses exactly one Terraform executor (pipeline or TFE); AAP must not race it or mutate Terraform-owned resources. See the architecture document for phase gates.
