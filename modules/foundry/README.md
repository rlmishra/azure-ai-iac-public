# Microsoft Foundry account and projects

Reusable AzureRM **5.13.0**, Terraform **1.17.2** module for the current Microsoft.CognitiveServices AIServices account/project architecture. This is distinct from the legacy MachineLearningServices hub architecture exposed by `azurerm_ai_foundry`.

Implemented resources: `azurerm_cognitive_account`, `azurerm_cognitive_account_project`, `azurerm_cognitive_deployment` and explicitly approved `azurerm_role_assignment` grants. No AzAPI, provisioners, secret values or fictional resources are used. Account/project creation is executable; deployment viability still requires approved Azure inputs and a real development plan.

## Use and ownership

The repository root and `environments/dev`, `test`, `prod` are complete compositions. They configure the provider, pass foundation dependencies, create the account private endpoint through `modules/networking`, and configure account diagnostics through `modules/monitoring`. The standalone module does **not** create a VNet, DNS zone, private endpoint, workspace, Key Vault or storage account. A standalone caller must supply that private connectivity and diagnostics independently; account public access cannot be enabled through this module.

The module requires `configuration`, `subscription_id`, `resource_group_name`, `location`, `approved_locations`, and `tags`. `key_vault_id`, `storage_account_id` and `openai_inference_principals` are optional. `configuration` requires `account_name`, a globally unique `custom_subdomain_name` and at least one named `projects` entry. Refer to `variables.tf` for the authoritative typed interface.

Each project has optional `display_name`, `description`, `grant_account_access`, `key_vault_secret_read`, `storage_blob_read`, and a `users` map. All grants default to false/empty. Each user entry has an Entra `principal_id` and `principal_type` (`User`, `Group` or `ServicePrincipal`). Human users receive no implicit grants. Projects and account use system-assigned identities.

Opt-in role boundaries:

| Input | Principal | Scope | Fixed role |
|---|---|---|---|
| `projects[*].grant_account_access` | That project's managed identity | Foundry account | Foundry User, formerly Azure AI User |
| `projects[*].users` | Explicit existing Entra objects | That project | Foundry User |
| `openai_inference_principals` | Explicit service principals/managed identities | Foundry account | Cognitive Services OpenAI User |
| `projects[*].key_vault_secret_read` | That project's managed identity | Supplied vault | Key Vault Secrets User |
| `projects[*].storage_blob_read` | That project's managed identity | Supplied storage account | Storage Blob Data Reader |

Foundry User is broader than inference-only and includes project operations; review its definition before enabling it. Project-to-account grants permit access to shared account capabilities. Account-scoped OpenAI User grants apply across applicable account deployments, not just one model. No subscription-wide or Owner/Contributor grants are created. Existing Phase 1 generic role allowlists remain unchanged.

## Model approvals

Model deployment defaults: `enable_model_deployments = false`, `approved_models = {}`, `deployments = {}`. Supplying a deployment while activation is false is rejected. Catalog entries explicitly contain:

| Catalog field | Meaning |
|---|---|
| `format`, `name`, `version` | Exact publisher format, catalog model and version approved by your organization; none is selected by the module |
| `permitted_regions` | Explicit permitted account regions |
| `permitted_skus` | Explicit permitted deployment SKUs; global/data-zone processing must be approved deliberately |
| `max_capacity` | Positive integer ceiling **per deployment**, not aggregate regional quota |

Each deployment key is its Azure deployment name. Its object contains `approval_id` referencing the catalog key, `sku_name`, positive integer `capacity`, and optional `rai_policy_name` referencing an independently managed existing policy. The model version is copied from the explicitly selected approval entry and `version_upgrade_option` is fixed to `NoAutoUpgrade`. Capacity units vary by model/SKU: do not treat them as universal TPM. Provisioned SKUs can incur hourly charges and require separate capacity/reservation/commercial arrangements. Azure quota, model availability, marketplace acceptance and retirement policies remain runtime prerequisites. Approval metadata is not evidence that Azure can fulfill a deployment.

Model data residency is not established by the account's location alone. Regional, data-zone, global and batch SKUs have different processing boundaries. This module accepts only documented SKU names and your explicitly approved choices; enterprise policy must independently govern which approvals may be supplied.

## Security and outputs

Public access, local/API-key authentication and trusted-service bypass are disabled. Network ACLs deny by default and outbound access is restricted. Encryption uses Azure-managed service keys; no account keys are exported. Account and project resources have `prevent_destroy`; the calling provider also disables purge on account destruction. Intentional model replacement/removal remains possible in a future reviewed plan; no model deployment apply is authorized by this source.

Outputs expose account ID, provider account endpoint, documented public-Azure OpenAI base hostname, account identity, project IDs/identities/service-returned endpoint maps, model deployment metadata, and security posture. Resolve the public hostnames through Private Link; do not substitute private-link hostnames in TLS application URLs. Project endpoint-map keys are service/provider-defined and are intentionally not guessed. The OpenAI base URL does not select a model, API route or API version. Other publisher inference contracts and roles require separate verification.

Storage/vault RBAC does not create project connections, secret objects, containers, agent state storage, runtime networking or permission propagation waits. Basic account/project provisioning does not require the legacy hub's storage/Key Vault dependency graph. Advanced agent services, network injection, tools, fine-tuning, compute, Search, CMK, gateways and content-filter customization are excluded. See [deployment guidance](../../docs/phase2/DEPLOYMENT.md), [capability evidence](../../docs/phase2/CAPABILITIES.md) and the Phase 2 validation report.
