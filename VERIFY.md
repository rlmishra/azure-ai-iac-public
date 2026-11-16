# Verify the Phase 1–3 source

Use this guide to inspect code and repeat local checks from the **azure-ai-phases-1-3** branch. This is source/configuration verification, not proof of deployed Azure/Gravitee functionality. No command below runs Terraform apply or destroy, starts/publishes an API, or creates a live subscription.

Use an approved development machine and repository access. If GitHub is blocked on a corporate laptop, obtain an approved internal mirror or transfer method from IT; changing repository visibility is not part of verification.

## 1. Get the correct branch

In Edge, open [the consolidated branch](https://github.com/rlmishra/azure-ai-iac/tree/azure-ai-phases-1-3). GitHub sign-in/repository permission is required because the repository is private.

For local verification, use PowerShell with Git and Terraform **1.17.2** installed. Clone into a new directory to avoid altering an existing working copy:

```powershell
git clone --branch azure-ai-phases-1-3 https://github.com/rlmishra/azure-ai-iac.git azure-ai-verification
Set-Location azure-ai-verification
git branch --show-current
git log -1 --format="%H %s"
git status --short
```

Expected branch: `azure-ai-phases-1-3`. A fresh clone should have a clean working tree. The consolidated implementation reference is commit `07e818cf28c43e6cab3fdeb099e0eda0e62fac5a`; this guide and future reviewed updates can produce later commits. Do not interpret that reference as an instruction to reset or discard local work.

## 2. Inspect the actual code

| Area | Main source | What to inspect |
|---|---|---|
| Foundation composition | [main.tf](main.tf) | Resource ownership and connections between modules |
| Network isolation | [modules/networking/main.tf](modules/networking/main.tf) | NSGs, private endpoints, linked DNS zones and outbound controls |
| Identity/RBAC | [modules/identity/main.tf](modules/identity/main.tf) | Explicit scoped grants and identity creation |
| Key Vault/storage | [modules/security/main.tf](modules/security/main.tf) | Private access, Entra/RBAC, retention and encryption settings |
| Monitoring | [modules/monitoring/main.tf](modules/monitoring/main.tf) | Private workspace/Application Insights and diagnostics |
| Foundry | [modules/foundry/main.tf](modules/foundry/main.tf) | Current AIServices accounts/projects, model approvals and scoped roles |
| Gravitee | [modules/gravitee/main.tf](modules/gravitee/main.tf) | JWT plans, exact routes, request quotas, backend identity and telemetry |
| Input checks | [Foundry variables](modules/foundry/variables.tf), [Gravitee variables](modules/gravitee/variables.tf) | Typed inputs and validation/activation guards |
| Azure environments | [environments/dev/main.tf](environments/dev/main.tf) | Separate dev/test/prod compositions and examples |
| Gateway environments | [gateways/dev/main.tf](gateways/dev/main.tf) | Separate gateway state and explicit activation |

For example, the Foundry account source includes these controls (excerpt, not a standalone configuration):

```hcl
kind                               = "AIServices"
project_management_enabled         = true
public_network_access_enabled      = false
local_auth_enabled                 = false
outbound_network_access_restricted = true
```

Gravitee API source keeps publication explicit:

```hcl
state           = var.publish_apis ? "STARTED" : "STOPPED"
visibility      = "PRIVATE"
lifecycle_state = var.publish_apis ? "PUBLISHED" : "UNPUBLISHED"
```

Read the whole resource and its variables/tests. A few secure-looking attributes do not establish end-to-end security or compatibility.

## 3. Repeat the full local verification

Prerequisites: Terraform 1.17.2, Git, Python 3 compatible with the pinned jsonschema dependency, and permitted provider/package-download access. Provider locks pin AzureRM **5.13.0** and, in separate gateway roots, gravitee-io/apim **1.2.0**.

If dependency installation is approved for your Python environment:

```powershell
python -m pip install -r tests/requirements-gravitee.txt
```

Then run from the cloned repository root:

```powershell
terraform.exe version
terraform.exe fmt -check -recursive
./tests/Validate-Local.ps1
./tests/Validate-Gravitee.ps1
```

The first helper initializes with backend disabled, validates and runs mocked tests in the reference Azure root and dev/test/prod Azure roots. The second checks all four gateway roots and runs the Python policy-schema checker. Both stop on command failure. Mocked Terraform tests specify `command = plan` and do not authenticate to Azure/APIM or change live resources. Backend-disabled initialization avoids remote-state access; use this fresh verification clone rather than a directory containing live state or actual tfvars.

Expected implementation-reference results:

| Suite | Mocked Terraform tests |
|---|---:|
| Azure reference root | 33 |
| Azure dev / test / prod | 14 each |
| Gateway reference root | 23 |
| Gateway dev / test / prod | 3 each |
| **Total** | **107 passed, 0 failed** |

The Python checker additionally verifies **71 rendered policy configurations** across 20 mock plans against seven pinned upstream schemas and the documented shared-group invocation contract. It reports `runtime_enforcement_verified: false`. These are configuration checks, not 71 live runtime tests. Future reviewed changes may deliberately change these counts; inspect their tests and validation reports.

## 4. Run a focused verification snippet

To inspect and test the Foundry module without a real Azure plan:

```powershell
terraform.exe init -backend=false -input=false -lockfile=readonly
if ($LASTEXITCODE -ne 0) { throw "Terraform init failed" }
terraform.exe validate
if ($LASTEXITCODE -ne 0) { throw "Terraform validation failed" }
terraform.exe test -filter=tests/foundry-module.tftest.hcl
if ($LASTEXITCODE -ne 0) { throw "Foundry mocked tests failed" }
```

For gateway policy checks:

```powershell
Push-Location gateways
try {
    terraform.exe init -backend=false -input=false -lockfile=readonly
    if ($LASTEXITCODE -ne 0) { throw "Gateway init failed" }
    terraform.exe validate
    if ($LASTEXITCODE -ne 0) { throw "Gateway validation failed" }
    terraform.exe test -filter=tests/gravitee-module.tftest.hcl
    if ($LASTEXITCODE -ne 0) { throw "Gateway mocked tests failed" }
} finally { Pop-Location }

python tests/check_gravitee_contracts.py --terraform terraform.exe
if ($LASTEXITCODE -ne 0) { throw "Policy schema verification failed" }
```

## 5. Compare results with committed evidence

- [Phase 1 validation](docs/VALIDATION.md)
- [Phase 2 validation](docs/phase2/VALIDATION.md)
- [Phase 3 validation](docs/phase3/VALIDATION.md)
- [Per-root test counts](docs/phase3/validation/test-counts.json)
- [Policy contract results](docs/phase3/validation/policy-contracts.json)
- [Secret-scan report](docs/phase3/validation/secret-scan.json)
- [Provider/plugin compatibility matrix](docs/phase3/CAPABILITIES.md)
- [Architecture](ARCHITECTURE.md)

Committed reports describe the recorded verification run; they do not automatically update when you execute commands locally. Inspect current outputs and command exit codes. Windows/PowerShell execution was not performed on the Linux build host; report any local failure rather than treating the saved logs as proof that your machine passed.

## 6. Recognize the remaining limits

Actual Gravitee server/gateway edition, licensing, plugin inventory and runtime compatibility remain unverified. The HTTP reference has a limited Azure VM IMDS backend-identity mode, not universal managed identity/workload federation. LLM token limits, AI guardrails and MCP/tool controls are **not implemented**; request-count quotas are not token budgets.

No deployed Foundry endpoint, private DNS/TLS path, JWT/subscription enforcement, distributed-counter behavior, IMDS token acquisition or telemetry privacy is established by mocked tests. Read the [Phase 3 deployment guide](docs/phase3/DEPLOYMENT.md) and [security checklist](docs/phase3/SECURITY-CHECKLIST.md) for approved live-development prerequisites. Keep deployment/publication disabled until those inputs and approvals are resolved. Never put credentials in chat, source or tfvars, and do not commit state, plans, live variable files or provider caches.
