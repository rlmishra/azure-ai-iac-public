# Phase 2 capability verification

Verified 2026-11-16. Base commit: `c5ae5bedbb527c55f68f3dd23ef7769778dab12f`. Terraform **1.17.2** and AzureRM **5.13.0** are unchanged. All four existing lock files are preserved byte-for-byte. No AzAPI gap exists for the implemented account/project/deployment requirements.

## Pinned provider evidence

| Capability | Verified AzureRM 5.13.0 surface | Decision |
|---|---|---|
| Current Foundry account | `azurerm_cognitive_account`: AIServices, S0, custom subdomain, project_management_enabled, identity, local_auth_enabled, public_network_access_enabled, outbound_network_access_restricted, network_acls | Implemented, private/keyless/restricted defaults |
| Current projects | `azurerm_cognitive_account_project`: cognitive_account_id, location, identity, description/display_name/tags, computed endpoints | Implemented, named projects and service-returned endpoint map |
| Models | `azurerm_cognitive_deployment`: model format/name/version, sku name/capacity, rai_policy_name, version_upgrade_option | Implemented behind activation + explicit approval catalog |
| Legacy hub/project | `azurerm_ai_foundry`, `azurerm_ai_foundry_project` use hub dependencies/MachineLearningServices | Inspected, intentionally excluded |
| Private connection | `azurerm_private_endpoint` plus existing networking DNS/NSG resources | Reused with group ID account and three documented zones |
| Diagnostics | Existing `azurerm_monitor_diagnostic_setting` | Reused with documented Audit and AllMetrics; live category confirmation pending |
| Project/app data permissions | `azurerm_role_assignment` | Explicit resource/project scopes and fixed supported built-in roles |
| Purge behavior | Provider `features.cognitive_account.purge_soft_delete_on_destroy` | Explicitly false in reference/dev/test/prod roots |

The installed `terraform providers schema -json` export was refreshed before implementation. `provider-schema.json` captures the three new service-resource schemas, supporting RBAC/diagnostic/private-endpoint schemas, and the provider cognitive-account feature block. Generic schemas verify shapes but do not prove runtime SKU, model availability, API permissions, quota or diagnostics support. Mocked plans additionally exercise provider validation.

Pinned provider documentation (the three current Cognitive resources document Microsoft.CognitiveServices API **2026-03-01**, selected internally by AzureRM; no REST body or API version is guessed by this module):

- https://github.com/hashicorp/terraform-provider-azurerm/blob/v5.13.0/website/docs/r/cognitive_account.html.markdown
- https://github.com/hashicorp/terraform-provider-azurerm/blob/v5.13.0/website/docs/r/cognitive_account_project.html.markdown
- https://github.com/hashicorp/terraform-provider-azurerm/blob/v5.13.0/website/docs/r/cognitive_deployment.html.markdown
- https://github.com/hashicorp/terraform-provider-azurerm/blob/v5.13.0/website/docs/r/ai_foundry.html.markdown
- https://github.com/hashicorp/terraform-provider-azurerm/blob/v5.13.0/website/docs/r/ai_foundry_project.html.markdown

Project creation requires AIServices kind, project_management_enabled=true, a managed identity and custom subdomain. All are configured. AzureRM defines create/read/update/delete and import behavior for these resources; project/account identity and location changes can cause replacement. Account/project prevent_destroy blocks destructive replacements while those blocks remain. No deployment is used to test lifecycle behavior.

## Official Azure evidence and limits

- Current architecture and project-to-account managed identity access: https://learn.microsoft.com/azure/foundry/concepts/architecture
- Foundry private connections and account/project DNS: https://learn.microsoft.com/azure/foundry/how-to/configure-private-link
- Private DNS matrix (Microsoft.CognitiveServices/accounts, group account): https://learn.microsoft.com/azure/private-link/private-endpoint-dns
- Role scopes/name rollout: https://learn.microsoft.com/azure/foundry/concepts/rbac-foundry
- Stable built-in role definitions: https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/ai-machine-learning
- Service log categories: https://learn.microsoft.com/azure/azure-monitor/reference/supported-logs/microsoft-cognitiveservices-accounts-logs

Microsoft documentation lists three applicable private zones: `privatelink.cognitiveservices.azure.com`, `privatelink.openai.azure.com`, `privatelink.services.ai.azure.com`. The account endpoint is shared by its projects; an independent unsupported project endpoint resource is not invented.

Role GUIDs confirmed from official built-in role JSON:

- Foundry User (formerly Azure AI User): `53ca6127-db72-4b80-b1b0-d745d6d5456d`.
- Cognitive Services OpenAI User: `5e0bd9bd-7b93-4f28-af87-19fc36ad61bd`.

Role display names may differ during rollout; subscription-qualified role_definition_id avoids display-name lookup drift. Foundry User includes broader project/data operations; it is not an inference-only role. No custom role capabilities are fabricated.

Unsupported or intentionally excluded from this implementation: hub-based Azure ML, feature-specific standard-agent resources/network injection, model marketplace purchases/terms, universal model endpoint contracts, custom content filtering, CMK workflows, runtime SDK hosting, Search, cross-region routing/DR and Gravitee. Some of these have provider surfaces, but support for the full end-to-end feature is not verified here. No AzAPI resources or manual imperative HTTP provisioning are used as shortcuts.
