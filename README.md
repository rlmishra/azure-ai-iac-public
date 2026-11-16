# Enterprise Azure AI infrastructure — Phases 1 and 2

Production-oriented Terraform source, **locally validated; not deployed**. Phase 1 provides the private Azure foundation. Phase 2 adds an opt-in Microsoft Foundry AIServices account, projects, explicitly approved model deployments and scoped identity integration. Gravitee, AAP and Azure DevOps implementation remain subsequent phases.

Start with [architecture](ARCHITECTURE.md), [Phase 2 capability evidence](docs/phase2/CAPABILITIES.md), [configuration/deployment guide](docs/phase2/DEPLOYMENT.md), [readiness checklist](docs/phase2/SECURITY-CHECKLIST.md), and [Phase 2 validation](docs/phase2/VALIDATION.md). The original [Phase 1 report](docs/VALIDATION.md) is historical evidence; it does not describe the new Foundry implementation.

## Repository and safe defaults

- `modules/networking`, `identity`, `security`, `monitoring`: existing Phase 1 foundation modules; their resource implementations and existing tests are preserved.
- `modules/foundry`: current Microsoft.CognitiveServices AIServices account/project architecture using official AzureRM resources, not the older hub-based Foundry/Azure ML resources.
- `environments/dev`, `test`, `prod`: independent deployment roots, examples, provider locks and mocked tests. Use separate backend state and permissions per environment.
- `tests`: unchanged Phase 1 regressions plus Foundry composition/module/negative-input checks.
- `modules/gravitee`, `ansible`, `pipelines`: later-phase status documentation; no gateway or orchestration implementation is claimed.

`foundry = null` in every default example preserves Phase 1 behavior. No model is selected, deployed or given capacity by default. Enablement requires an explicit account/subdomain and project map; models also require separate activation and an explicit approval catalog. Read `modules/foundry/variables.tf` for the complete typed interface.

The root is a reference composition and test entry point. Deploy from the chosen environment root. Never deploy the reference root and an environment root to the same resources. Environment roots compose the same modules; keep composition changes synchronized.

## Windows 11 local development

Use VS Code, Git, Terraform **1.17.2** (`terraform.exe`) and approved enterprise Azure tooling. AzureRM remains **5.13.0**; the unchanged lock files contain verified Linux/Windows amd64 provider checksums. From this repository root in PowerShell:

```powershell
terraform.exe version
terraform.exe fmt -check -recursive
terraform.exe init -backend=false -input=false
terraform.exe validate
terraform.exe test
./tests/Validate-Local.ps1
```

The helper repeats checks in all four roots and stops on errors. Mocked tests use only `command = plan`; they never authenticate to Azure or provision resources. `init -backend=false` avoids remote-state access during offline validation. These commands need registry/provider downloads but no Azure credentials. Windows execution remains a handoff check; the recorded test host is Linux.

## Prepare a reviewed development plan

1. Approve subscription/tenant, unique names, region/data-processing boundary, IP allocation, DNS ownership, model/version/SKU/capacity and identity grants. No example/test value constitutes organizational approval.
2. In the chosen environment, copy `terraform.tfvars.example` to `terraform.tfvars` and replace illustrative foundation inputs. Keep Foundry null for Phase 1-only behavior.
3. To opt into Phase 2, copy `foundry.tfvars.example` to `foundry.tfvars`, approve its settings, and supply it as the second var file. It initially creates no models or RBAC grants.
4. Use an existing separately bootstrapped private backend account/container. Copy `docs/backend.tf.example` into that environment as `backend.tf`, and prepare `backend.hcl` from `docs/backend.hcl.example`. Use unique environment state keys, Entra data access, locking, encryption, versioning and tested recovery. The application storage created by this stack is not its own state backend.
5. Authenticate through approved CLI or workload identity federation. The runner supplies identity/token delivery externally; never put account keys, access tokens or secret values in Terraform variables or chat. AzureRM automatic resource-provider registration stays disabled; landing-zone administrators must register required providers, including Microsoft.CognitiveServices for Phase 2.
6. Only with approved development credentials and backend access:

```powershell
Set-Location environments/dev
terraform.exe init -backend-config=backend.hcl
terraform.exe validate
terraform.exe test
terraform.exe plan -input=false -var-file=terraform.tfvars -var-file=foundry.tfvars -out=dev-foundry.tfplan
```

Omit the Foundry overlay for a foundation-only plan. Review the full plan, inherited policy outcomes, role assignments, costs, quota and diagnostic categories. Protect state/plans/evidence as confidential artifacts. **Apply/destroy and cloud deployment require separate explicit approval and were not performed.**

## Security and responsibility boundaries

Key Vault, blob storage, monitoring and enabled Foundry data endpoints require private DNS/routing. Trusted source CIDRs change NSG access but do not create routing, peering, private runners or DNS forwarders. Foundry adds one account private endpoint and three service zones through the existing networking owner. Public access and API-key authentication remain disabled.

Foundry account/project system identities are separate from the existing application user-assigned identity. All role grants are explicit and scoped; the Phase 1 identity allowlist is unchanged. Project-to-account Foundry User, project-user access, project vault/blob reads and application OpenAI inference are separately approved switches/maps. Vault/blob RBAC does not configure agent connections or runtime networking.

Azure-managed encryption is the implemented baseline. CMK/key lifecycle, enterprise policy/landing-zone mappings, workload-host identity attachment, sensitive-data redaction, alerts, capacity purchases, recovery and DR need organizational decisions and live validation. Empty policy-assignment inputs do not establish compliance. Storage replication alone is not AI application failover.

Account/project and foundation data resources have Terraform deletion protections as documented; removing configuration can remove Terraform lifecycle protection. No secret values are managed in state. Provider-generated state and plans can still contain sensitive metadata; never commit them.

Phase 3 must inspect official Gravitee provider/server/plugin compatibility and distinguish consumer authentication from backend Entra token acquisition. Phase 4 AAP owns post-deployment validation/evidence; Phase 5 chooses a single Terraform executor and governs approvals. No duplicate executor, gateway governance, agent runtime or application hosting is introduced by Phase 2.
