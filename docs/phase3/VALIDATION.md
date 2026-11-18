# Phase 3 validation report

Date: 2026-11-16. Host: managed Linux amd64. Base: verified remote phase2-microsoft-foundry commit `d002f3e338dfd0073e11ba401ade7226fd4e6d9d`. Worktree: `/workspace/work/phase3-gravitee-ai-gateway`; branch `phase3-gravitee-ai-gateway`.

## Successful local checks

| Check | Result / evidence |
|---|---|
| Base verification | Requested remote Phase 2 exists; actual source/outputs/private network/RBAC and Phase 2 report inspected before coding |
| Provider verification | Official gravitee-io/apim 1.2.0 installed, developer signature key 943FC12BEA201174; installed provider/resource schemas and pinned official examples/docs inspected |
| Policy configuration evidence | Seven Git-tree-pinned upstream JSON schemas, plugin IDs from official plugin.properties, provenance URLs/hashes and upstream license retained |
| Provider locks | Four separate gateway roots have pinned Linux/Windows amd64 checksums; all existing Azure provider pins/locks unchanged |
| Recursive format | PASS; validation/fmt.log |
| Azure reference/dev/test/prod init/validate/tests | PASS; 33 + 14 + 14 + 14 = **75** existing regression test runs |
| Gateway reference init/validate/tests | PASS; **23** mocked runs (20 module cases, 3 root cases) |
| Gateway dev/test/prod init/validate/tests | PASS; **3** mocked root scenarios each |
| Total Terraform tests | **107 passed, 0 failed** across eight roots; validation/test-counts.json and per-root logs |
| Rendered JSON policy contract checks | PASS; **71** configurations checked across **20** verbose mock plans; seven schema hashes verified; validation/policy-contracts.json |
| Examples | All HCL/JSON tfvars examples parse; validation/example-parsing.json. Values are illustrative, not approvals or availability claims |
| Azure preservation | Every pre-existing .tf/lock file byte-identical to Phase 2 base; validation/azure-preservation.json |
| Original Phase 1 preservation | All 86 original source files still match the original ZIP, whose SHA-256 remains 319e80108662793671d125bcda8be46e2c66a7fe339c2f351ea913739c875794 |

Final command exit codes are in validation/results.json. All roots ran `terraform init -backend=false -input=false`, `terraform validate`, and `terraform test`; recursive formatting was checked from the repository root. Cached provider binaries are an optimization only. All test runs use mocked providers and `command = plan`; no live provider plan, apply or destroy ran.

The Python checker reads actual verbose JSON mock-plan resource changes, not a hand-maintained copy of configuration. It validates JWT/HTTP-callout/Interrupt/header/query/rate/quota JSON against the recorded schemas and checks shared-group invocation against the pinned provider example. It checks private visibility, mandatory exact POST operation, content/header/OTel logging defaults, fail-closed synchronous limits and absence of API-key subscription configuration. Python jsonschema 4.26.0 is pinned in tests/requirements-gravitee.txt. Repeated rendered checks do not represent 71 distinct policy types or runtime tests.

The Terraform cases cover private/stopped drafts, JWT application association, control order, query version pinning, fixed-host fail-closed VM token retrieval, explicit publication/subscriptions and redacted opt-in telemetry. Negative cases reject HTTP/project/MCP endpoints, missing approvals, mismatched deployment IDs, fractional limits, overlapping paths, unconfirmed licenses/topology, runtime mismatch, missing plugins, unreviewed analytics/tracing, common tenant, role-expression injection, draft subscriptions, expired subscriptions and missing activation inputs. They check configuration contracts, not actual tokens or running policies.

## Failures corrected during implementation

No final check failures. Initial HCL generation formatting/escape errors were corrected before successful provider validation. An initial policy-order assertion compared tuple/list types rather than normalized lists; the fixture was corrected. An activation-input test expected a dependent validation error that Terraform did not evaluate after the primary failure; its expected diagnostic was narrowed. Explicit telemetry-gating checks were then updated and passed. No live resource or production credential was used to debug these checks.

The hosted Gravitee documentation site returned HTTP 403 to research requests; versioned official provider GitHub docs/examples and immutable official policy GitHub schemas were used instead. Actual target platform/version/edition/plugins/licenses were requested but not supplied. This remains a runtime compatibility dependency, not a successful observed platform check.

## Not executed / unresolved dependencies

- **Live APIM server/gateway/Automation API/license/plugin compatibility:** actual inventory, endpoint and approved service-account access were not supplied. APIM 4.13.x is a candidate reference, not an observed installation. Test plugin-version strings and review flags are synthetic fixtures.
- **Real Gravitee or Azure plan / apply / destroy / API start/publication / subscriptions / policy updates:** no approved development platform/state credentials or deployment authorization; none performed.
- **Phase 2 deployment/model availability and metadata correctness:** Phase 2 has locally validated source but no approved Azure deployment. No live endpoints/models were fabricated.
- **Live JWT signature/time/claim/subscription/role enforcement and manual subscription behavior:** require approved test identities and a deployed target.
- **VM IMDS token acquisition, RBAC, token failure behavior and token confidentiality:** JSON matches official policy schema and Microsoft protocol, but no gateway VM/UAMI/IMDS runtime was tested. No cache is implemented; latency/concurrency/SSRF restrictions need review.
- **Routing/TLS/private DNS/encoded-path/query/header/streaming behavior and distributed limit-store failure semantics:** need actual runtime/network settings and approved smoke tests.
- **OTel collection, metadata/IP minimization, host logging, retention and redaction enforcement:** no collector/platform is configured here. API configuration checks do not prove host-wide privacy.
- **LLM token limits/spend accounting, AI guardrails, MCP/tool restrictions, native LLM/unified inference and non-VM federation:** explicitly unimplemented pending verified plugin/schema/protocol/edition requirements. Request quotas are not token controls.
- **Windows/PowerShell helper execution:** host is Linux. Windows provider checksums are retained; Windows execution and the manual metadata-export helper were not run.
- **TFLint and complete organizational policy/IaC security certification:** not configured by this phase. Secret/content scanning is separately recorded before publication and is not a security certification.

The local source-validation gate passes. Deployment readiness remains conditional on the actual inventory/entitlement, approved Phase 2 metadata/identity/network/state, a real inspected development plan, separate apply authorization and runtime checks in DEPLOYMENT.md / SECURITY-CHECKLIST.md. No checklist or boolean input grants deployment permission.

## Proposed commit secret/content scan

Gitleaks 8.30.1 scanned the full proposed repository export with zero final findings. Sensitive-file-name and literal-credential checks found no state/plans, actual variable files, credentials or private keys. Fixtures contain synthetic IDs/approvals; source/license/schema material is public upstream evidence, and no actual confidential workload/customer data was identified. An initial generic-api-key finding matched non-secret README prose about disabled flags; wording was adjusted and rescanned without rule suppression. See validation/secret-scan.json. Pattern scanning is not a proof of secret absence or host-wide runtime privacy.
