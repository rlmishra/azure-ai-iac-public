# Implementation status

| Phase | Source status | Validation status | Unresolved dependencies |
|---|---|---|---|
| 1 — Azure foundation | Implemented in four reusable modules and dev/test/prod roots | Local schema, fmt, init, validate and mocked tests pass | Approved cloud inputs, state/credentials, landing-zone DNS/policy, real plan and post-deployment tests |
| 2 — Microsoft Foundry | Implemented: current AIServices account/projects, approved model deployments, private connectivity, RBAC and diagnostics | See phase2/VALIDATION.md for local checks; no Azure deployment | Approved actual account/model/region/SKU/capacity, quota/entitlement, DNS/policy/credentials and runtime evidence |
| 3 — Gravitee | Implemented: separate official-provider HTTP API/app/subscription/shared-policy roots; optional reference VM IMDS auth | See phase3/VALIDATION.md; no live runtime checked | Actual server/gateway edition/plugins/license, approved metadata/identity/network/counters; AI token/guardrail/MCP controls unimplemented |
| 4 — AAP | Pending | Not run | AAP execution environment/collections, private runner network, evidence storage, optional ServiceNow API contract and Terraform execution ownership |
| 5 — Azure DevOps | Pending | Not run | Service connections and WIF, protected environments/approvals, scanner/policy tooling, artifact retention, pipeline versus TFE execution decision |

Phases 1 and 2 plus a scoped Phase 3 HTTP gateway baseline have executable source. Phase 3 AI token/guardrail/MCP extensions and Phases 4–5 remain pending. Never use a successful mock test as approval to provision infrastructure.
