# Private access / managed identity validation

Date: 2026-11-18. Base commit: `018b4cadb54013de32cb5dc8b13a9b1190d460a5`. Branch: `security-private-access-managed-identity`. Host: managed Linux amd64. No actual target resource, gateway or production state was accessed.

## Successful checks

| Check | Result |
|---|---|
| Authentication / destination | Private source repository; authenticated identity has push permission; verified before work and rechecked before publication |
| Local instructions / branch | No applicable AGENTS.md found; clean consolidated base; isolated new worktree/branch; existing branches and worktrees preserved |
| Provider/service capabilities | Installed AzureRM 5.13.0 schema inspected; version-pinned AzureRM/Gravitee docs and official Microsoft service docs retrieved; no AzAPI introduced |
| Formatting | `terraform fmt -check -recursive`: PASS |
| Initialization | Eight roots: `init -backend=false -input=false -lockfile=readonly`: PASS |
| Validation | All eight roots: PASS |
| Azure reference root | 42 mocked tests passed |
| Azure dev/test/prod | 18 mocked tests each passed |
| Gateway reference root | 28 mocked tests passed |
| Gateway dev/test/prod | 3 mocked tests each passed |
| Total | **133 passed, 0 failed**; includes all existing 107 regression scenarios plus 26 additional cases |
| Policy contracts | **81 rendered configurations** checked across **25** verbose mocked plans; seven recorded upstream schema hashes verified |
| Preservation | Every versions.tf and provider lock file byte-identical to base. Foundry, security and monitoring module source unchanged. Existing endpoint/role resource addresses retained |

The policy count includes repeated rendered policy objects and partial mock plans from expected-invalid-input scenarios, not 81 distinct policies or live checks. Runtime enforcement remains false. Existing provider/resource schema evidence and examples remain in the earlier phase directories; this report supersedes earlier test counts for this branch only.

New tests exercise independent vault/blob/telemetry grants with no unrelated permissions, explicit no-grant defaults, rejection of unowned DNS and missing endpoint groups, correct four-service group/zone ownership including shared blob DNS, no vault/storage public/key/trusted-service fallback, Insights/LAW Entra-private configuration, and missing/non-VM hosting or unreviewed backend RBAC. Existing Phase 1/2 tests also cover rejected broad role scopes, private Foundry/account defaults, approval requirements and invalid models. Gateway tests retain unpublished/private defaults, credential stripping, exact routes and failure controls.

All Terraform test runs use mocked providers and `command = plan`. No live provider plan was executed. Raw command logs are kept in local scratch `/workspace/work/private-access-review`; [validation-results.json](validation-results.json) records command exit codes and counts without live configuration or tokens.

## Failures

No final format/init/validate/test/contract failures. Targeted new cases passed before the full regression run. No Azure/API call was used to debug these checks.

## Not executed / deployment blockers

- Real Terraform plan, live backend initialization/migration/state access: no approved development credentials/state target provided.
- Apply/destroy, Azure provisioning, gateway publication/start/subscription creation: prohibited; none executed.
- Private DNS resolution, TLS, routing, NSGs/UDRs/hub forwarding, private runner reachability and PE approval: no approved live target or network access supplied.
- Actual VM identity attachment, IMDS token acquisition, SDK Entra auth, role propagation, least-privilege acceptance and cross-tenant behavior: not tested. Creating roles/identities is not evidence of usable runtime identity.
- Actual APIM edition/license/plugin/runtime/schema compatibility, Management API authentication and vendor dependencies: inventory/access not provided. MI-only management login is not established by provider 1.2.0.
- Foundry actual model/region/SKU availability, quota and project-feature egress: not verified; model creation remains opt-in.
- Monitor data delivery/categories and DCE/DCR requirements, collector/privacy controls and retention: no actual collection workflow or runtime checked.
- Windows/PowerShell helper execution, full organizational security certification and real disaster recovery: not executed. Both helper initializations now retain locks read-only.
- LLM token limits, AI guardrails and MCP/tool controls: remain unimplemented; no scope expansion or runtime claims.

## Secret/content review

Before publication, the exact staged tree is exported and scanned with Gitleaks 8.30.1 and sensitive-file/literal checks. Results are recorded in [secret-scan.json](secret-scan.json). Provider caches, credentials, live tfvars, state/plans and private keys must not be committed. Fixtures contain synthetic IDs and official role IDs; evidence contains public source URLs/schema metadata. Scanning is not a guarantee of secret absence or organizational certification.
