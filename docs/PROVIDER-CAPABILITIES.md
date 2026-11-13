# Provider verification — Phase 1

Verified on 2026-11-13 against official release/registry endpoints and installed binaries. These versions are reproducible pins, not a promise that future releases keep the same schemas.

| Dependency | Selection | Evidence |
|---|---|---|
| Terraform CLI | 1.17.2 | `https://checkpoint-api.hashicorp.com/v1/check/terraform`; release ZIP checked against official SHA256SUMS |
| AzureRM | 5.13.0 | `https://registry.terraform.io/v1/providers/hashicorp/azurerm`; signed HashiCorp provider installation; binary schema export |
| AzAPI | Not included | No Phase 1 capability gap found; adding an unused provider is unnecessary |
| Gravitee APIM | Not selected in Phase 1 | Must inspect official `gravitee-io/apim` provider schema and server compatibility in Phase 3 |

`docs/validation/phase1-provider-schema.json` is a resource-schema excerpt from `terraform providers schema -json` using the installed AzureRM binary. It includes all 19 resource types used by this implementation. Its schema export SHA-256 is recorded in the validation report. Attributes and block shapes are confirmed by `terraform validate` and mocked provider plan validation; Azure runtime acceptance is not implied.

## Confirmed AzureRM resources

- Network: `azurerm_resource_group`, `azurerm_virtual_network`, `azurerm_subnet`, `azurerm_network_security_group`, `azurerm_network_security_rule`, `azurerm_subnet_network_security_group_association`, `azurerm_private_dns_zone`, `azurerm_private_dns_zone_virtual_network_link`, `azurerm_private_endpoint`.
- Identity: `azurerm_user_assigned_identity`, `azurerm_role_assignment`.
- Security/governance: `azurerm_key_vault`, `azurerm_storage_account`, `azurerm_resource_group_policy_assignment`.
- Monitoring: `azurerm_log_analytics_workspace`, `azurerm_application_insights`, `azurerm_monitor_private_link_scope`, `azurerm_monitor_private_link_scoped_service`, `azurerm_monitor_diagnostic_setting`.

Important verified 5.x details: DNS VNet links take `private_dns_zone_id`; Key Vault uses `rbac_authorization_enabled`; Log Analytics uses `internet_ingestion_access_type` and `internet_query_access_type`; storage uses `public_network_access`; diagnostic metrics use `enabled_metric`. Older examples often use incompatible or deprecated forms. The initial DNS-link mismatch was caught and corrected during validation.

Value constraints not exposed in the generic JSON schema were checked through provider plan validation. Log Analytics access enum documentation was also retrieved from the pinned release:

- https://github.com/hashicorp/terraform-provider-azurerm/blob/v5.13.0/website/docs/r/log_analytics_workspace.html.markdown
- https://github.com/hashicorp/terraform-provider-azurerm/blob/v5.13.0/website/docs/r/storage_account.html.markdown
- https://github.com/hashicorp/terraform-provider-azurerm/blob/v5.13.0/internal/services/storage/storage_account_resource.go

The storage account source uses the management-plane `storageClient.BlobServices.SetServiceProperties` for `blob_properties`; this avoids a data-plane/private-endpoint creation cycle in this pinned version. Future storage-container/blob resources may need private runner reachability and data-plane permissions. `storage_use_azuread = true` is enabled for that authentication posture, without adding data objects now.

## Service-level assumptions requiring a real development environment

Private Link group IDs are the documented `vault`, `blob` and `azuremonitor`. The AMPLS zone group includes the documented five Azure Monitor zones. Confirm current service requirements and existing shared-zone ownership before approval:

- https://learn.microsoft.com/azure/azure-monitor/logs/private-link-configure
- https://learn.microsoft.com/azure/azure-monitor/logs/private-link-design
- https://learn.microsoft.com/azure/private-link/private-endpoint-dns
- https://learn.microsoft.com/azure/storage/common/monitor-storage-reference

Diagnostic categories in the composition are Key Vault `audit`/`AllMetrics`, storage account `Transaction`, and blob service `StorageRead`, `StorageWrite`, `StorageDelete`/`Transaction`. Verify each against `az monitor diagnostic-settings categories list --resource <approved-resource-id>` after a development deployment; the provider schema cannot verify service categories. No generic network diagnostic category was invented.

Foundry feature support, projects, model names/capacity, agents, Gravitee policy plugins, token counters, guardrails, MCP controls and gateway OpenTelemetry are **not verified or implemented in Phase 1**. The pending directories contain no Terraform resources pretending to implement those capabilities.
