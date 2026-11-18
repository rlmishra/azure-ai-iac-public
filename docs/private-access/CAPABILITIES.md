# Verified capability evidence

Reviewed 2026-11-18 against installed Terraform **1.17.2**, AzureRM **5.13.0** and Gravitee provider **1.2.0**. No pins or provider lock files were changed. No AzAPI capability gap was demonstrated; none was added.

## Provider evidence

[provider-schema-evidence.json](provider-schema-evidence.json) records installed AzureRM schema attributes and PE nested blocks used in this review. It is type/attribute evidence, not proof of service availability or runtime security. The unchanged Phase 3 schema is in [../phase3/provider-schema.json](../phase3/provider-schema.json).

Pinned official AzureRM documentation retrieved successfully:

- [Key Vault 5.13.0](https://github.com/hashicorp/terraform-provider-azurerm/blob/v5.13.0/website/docs/r/key_vault.html.markdown): public access off, RBAC on, network bypass None.
- [Storage 5.13.0](https://github.com/hashicorp/terraform-provider-azurerm/blob/v5.13.0/website/docs/r/storage_account.html.markdown): public_network_access Disabled, shared_access_key_enabled false, local_user_enabled false, default_to_oauth_authentication true.
- [Private endpoint 5.13.0](https://github.com/hashicorp/terraform-provider-azurerm/blob/v5.13.0/website/docs/r/private_endpoint.html.markdown): private_service_connection target/subresource_names and private_dns_zone_group.
- [AMPLS 5.13.0](https://github.com/hashicorp/terraform-provider-azurerm/blob/v5.13.0/website/docs/r/monitor_private_link_scope.html.markdown): PrivateOnly ingestion/query.
- [Application Insights 5.13.0](https://github.com/hashicorp/terraform-provider-azurerm/blob/v5.13.0/website/docs/r/application_insights.html.markdown): disable public ingestion/query and local authentication; application SDK credential remains external.
- [Cognitive account 5.13.0](https://github.com/hashicorp/terraform-provider-azurerm/blob/v5.13.0/website/docs/r/cognitive_account.html.markdown): AIServices projects, identity, private network/local-auth controls. Preserve the existing modern account architecture.
- [Role assignment 5.13.0](https://github.com/hashicorp/terraform-provider-azurerm/blob/v5.13.0/website/docs/r/role_assignment.html.markdown): resource scope, principal and role definition name/ID. Existing role names and resource addresses are retained; there is no role ID migration.

## Service and authentication evidence

- [Private endpoint DNS service table](https://learn.microsoft.com/azure/private-link/private-endpoint-dns): groups/zones for vault, blob, Cognitive Services and Azure Monitor. The networking module remains the sole zone/PE owner, including the blob zone shared with AMPLS.
- [Storage private endpoints](https://learn.microsoft.com/azure/storage/common/storage-private-endpoints): endpoints are service-specific. Blob coverage is not DFS/File/Queue/Table coverage; regular account hostnames should resolve privately.
- [Vault Private Link](https://learn.microsoft.com/azure/key-vault/general/private-link-service): data-plane private connectivity and separate authorization.
- [Azure Monitor Private Link](https://learn.microsoft.com/azure/azure-monitor/fundamentals/private-link-security): AMPLS scope modes, DNS, supported ingestion/query boundaries. DCE/DCR/AMA are not introduced without an actual collection workflow.
- [Insights Entra authentication](https://learn.microsoft.com/azure/azure-monitor/app/azure-ad-authentication): SDK Entra configuration plus Monitoring Metrics Publisher; connection metadata alone is insufficient.
- [Foundry network isolation](https://learn.microsoft.com/azure/ai-foundry/how-to/configure-private-link?view=foundry): account/project feature-specific limitations; do not generalize to managed agent/tool egress.
- [Azure VM managed identity token protocol](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/how-to-use-vm-token): VM IMDS and explicit user-assigned identity selection. It is link-local host access, not a Private Link service.
- [AzureRM backend authentication](https://developer.hashicorp.com/terraform/language/backend/azurerm): use_azuread_auth, use_msi for supported Azure-hosted runners or use_oidc for reviewed federation; backend storage connectivity is independent of identity.
- [Gravitee provider 1.2.0 authentication](https://github.com/gravitee-io/terraform-provider-apim/blob/v1.2.0/docs/index.md): service-account bearer/cloud and other documented management credentials. No documented Azure managed identity management login was established. VM backend identity is a different flow.

Microsoft Learn pages describe evolving service behavior and are not API-version pins. Exact deployed region, resource API/feature behavior, DNS, diagnostics, provider/runtime compatibility and entitlement require live development verification. Source retrieval URLs, status and SHA-256 evidence are retained in [source-retrieval.json](source-retrieval.json).

## Verified built-in roles

| Use | Built-in role | Stable role GUID | Scope used/intended |
|---|---|---|---|
| Secret read | Key Vault Secrets User | `4633458b-17de-408a-b874-0445c86b69e6` | Existing vault |
| Blob read | Storage Blob Data Reader | `2a2b9908-6ea1-4ae2-8e65-a410df84e7d1` | Existing storage account; container narrowing requires actual container ownership/design |
| SDK telemetry | Monitoring Metrics Publisher | `3913510d-42f4-4e42-8a64-420c390055eb` | Existing Insights component |
| Inference | Cognitive Services OpenAI User | `5e0bd9bd-7b93-4f28-af87-19fc36ad61bd` | Approved Foundry account; existing Phase 2 grant remains independent |
| Backend state lease/read/write | Storage Blob Data Contributor | `ba92f5b4-2d11-453d-a403-e96b0029c9fe` | External state container; not assigned here |

Official role sources: [security](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security), [storage](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage), [monitoring](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/monitor), [AI and ML](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/ai-machine-learning). Built-in names are still resolved by AzureRM for existing foundation grants; GUIDs are evidence for operator review, not a new resource or broader authorization.
