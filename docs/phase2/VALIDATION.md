# Phase 2 validation report

Date: 2026-11-16. Host: managed Linux amd64. Base: Phase 1 commit `c5ae5bedbb527c55f68f3dd23ef7769778dab12f`. Branch: `phase2-microsoft-foundry`. Worktree: `/workspace/work/phase2-microsoft-foundry`.

## Successful checks

| Check | Result / evidence |
|---|---|
| Requested base verification | Private repository authenticated; remote Phase 1 ref resolved to the recorded base before creating an isolated worktree |
| Installed provider schema | Refreshed AzureRM 5.13.0 schema; all **22** resource types in the combined source present; new capability evidence matches the checkout's installed schema |
| Terraform/provider compatibility | Terraform 1.17.2, AzureRM 5.13.0; all four original versions.tf and .terraform.lock.hcl files byte-identical to base; no AzAPI/provider upgrade |
| Recursive formatting | PASS, validation/fmt.log |
| Reference root init/validate/test | PASS; **33** mocked test runs, zero failures |
| Dev init/validate/test | PASS; **14** mocked test runs, zero failures |
| Test init/validate/test | PASS; **14** mocked test runs, zero failures |
| Prod init/validate/test | PASS; **14** mocked test runs, zero failures |
| Existing Phase 1 regression coverage | All **36** original test runs across the four roots retained and passing |
| New Phase 2 coverage | **39** additional runs: 15 standalone module cases and six composition scenarios repeated across four roots |
| Total | **75 passed, 0 failed**; command exit codes in validation/results.json and readable logs in validation/ |
| Example HCL parsing | All seven tfvars examples parse; validation/example-parsing.json. This does not approve values or establish Azure availability |
| Original Phase 1 source/archive preservation | Original `/workspace/azure-ai-iac` still matches all 86 ZIP entries; ZIP SHA-256 unchanged |

Command set: recursive `terraform fmt -check -recursive`; then `terraform init -backend=false -input=false`, `terraform validate` and `terraform test` in the reference/dev/test/prod roots. Provider binaries were reused from the existing local cache via TF_PLUGIN_CACHE_DIR; cache location does not change provider selection. All test runs specify `command = plan` and use mocked providers. No apply-mode tests or real Azure plans ran.

Tests exercise current AIServices/project selection, public/local-auth/outbound/network defaults, no automatic models/grants, one added account endpoint and three zones, preservation of foundation defaults, approved project/runtime and workload-inference grants, role GUIDs/scopes, explicit model versions/capacity/NoAutoUpgrade, and rejection of unknown approvals, disallowed region/SKU, excessive/fractional capacity, missing model version, unactivated deployment, missing projects/data scopes, invalid principals/account names and disabled-account inference grants. They validate configuration/plan contracts, not runtime service behavior.

The evidence excerpt `provider-schema.json` SHA-256 is:

```text
da816bb5cfdccc974bc85c73be44dfe0fe26ab2a1a34d75b4f0b9dd9b6e4ba97
```

Original Phase 1 ZIP SHA-256 (unchanged):

```text
319e80108662793671d125bcda8be46e2c66a7fe339c2f351ea913739c875794
```

## Failures and corrections

No final Terraform check failures. The initial standalone test fixture represented a nested mocked identity block as a tuple/list; Terraform expects a mock object for that block. Correcting the test fixture resolved the failure; the final module suite and all root suites passed. No live resource was used to debug it.

## Not executed / deployment blockers

- Real Azure terraform plan: no approved Azure development credentials or backend access configured. GitHub authorization is separate and does not grant Azure access.
- Terraform apply/destroy, actual resource creation, production-secret access: not authorized; none executed.
- Actual region/account/project/model availability, names, quotas, capacity units, entitlement, marketplace terms and policy evaluation: need approved subscription inputs and live Azure evidence.
- Private endpoint approval, DNS/private routing, public-denial checks, SDK inference, Entra token audiences, role propagation and cross-project isolation: require a separately approved deployment and private runner/test identities.
- Live diagnostic category discovery, telemetry canaries, sensitive-metadata/redaction checks, alerts and retention verification: require deployed resources and monitoring access. Audit/AllMetrics are documented/configured, not live-confirmed.
- Windows CLI/PowerShell execution: host is Linux; Windows provider checksums are retained, but execution is unverified.
- TFLint, comprehensive security scanning of Azure configuration and organizational policy-as-code suite: not installed/configured in this phase. Secret scanning is separately recorded below and is not an IaC security certification.
- CMK, advanced agent/tool networking/runtime, custom content-filter policies, recovery/DR exercises and Gravitee: explicit exclusions or subsequent phases.

The local source-validation gate passes. Deployment readiness remains conditional on approved organization inputs, a real development plan, explicit apply authorization and post-deployment tests. See SECURITY-CHECKLIST.md and DEPLOYMENT.md.

## Proposed commit secret/content scan

Gitleaks 8.30.1 scanned the full staged repository export with zero findings. File-name checks found no credentials, live tfvars, private keys, Terraform state or plan artifacts. Literal credential-assignment checks found none; all UUIDs were synthetic fixtures or official built-in role GUIDs. Classification terms were example tags and documentation; no actual confidential workload/customer data was identified. See validation/secret-scan.json. Pattern scans cannot guarantee absence of all secrets or establish enterprise disclosure approval; the authorized private GitHub destination is independently rechecked before push.
