locals {
  name = "${var.name}-${var.environment}"
  tags = merge(var.tags, { environment = var.environment, managed_by = "terraform" })
}
resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name}"
  location = var.location
  tags     = local.tags
}
module "security" {
  source                   = "./modules/security"
  name                     = local.name
  resource_group_name      = azurerm_resource_group.this.name
  resource_group_id        = azurerm_resource_group.this.id
  location                 = var.location
  tags                     = local.tags
  tenant_id                = var.tenant_id
  key_vault_name           = var.key_vault_name
  storage_account_name     = var.storage_account_name
  storage_replication_type = var.storage_replication_type
  policy_assignments       = var.policy_assignments
}
module "monitoring" {
  source              = "./modules/monitoring"
  name                = local.name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = local.tags
  retention_in_days   = var.retention_in_days
  diagnostic_targets = merge({
    vault   = { resource_id = module.security.key_vault_id, log_category_groups = ["audit"], metric_categories = ["AllMetrics"] }
    storage = { resource_id = module.security.storage_account_id, metric_categories = ["Transaction"] }
    blob    = { resource_id = module.security.blob_service_id, log_categories = ["StorageRead", "StorageWrite", "StorageDelete"], metric_categories = ["Transaction"] }
    }, var.foundry == null ? {} : {
    foundry = { resource_id = module.foundry[0].account_id, log_categories = ["Audit"], metric_categories = ["AllMetrics"] }
  })
}
module "networking" {
  source              = "./modules/networking"
  name                = local.name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = local.tags
  address_space       = var.address_space
  workload_prefixes   = var.workload_prefixes
  endpoint_prefixes   = var.endpoint_prefixes
  trusted_prefixes    = var.trusted_prefixes
  dns_servers         = var.dns_servers
  private_endpoints = merge({
    vault   = { resource_id = module.security.key_vault_id, subresource_names = ["vault"], dns_zone_names = ["privatelink.vaultcore.azure.net"] }
    blob    = { resource_id = module.security.storage_account_id, subresource_names = ["blob"], dns_zone_names = ["privatelink.blob.core.windows.net"] }
    monitor = { resource_id = module.monitoring.private_link_scope_id, subresource_names = ["azuremonitor"], dns_zone_names = ["privatelink.monitor.azure.com", "privatelink.oms.opinsights.azure.com", "privatelink.ods.opinsights.azure.com", "privatelink.agentsvc.azure-automation.net", "privatelink.blob.core.windows.net"] }
    }, var.foundry == null ? {} : {
    foundry = { resource_id = module.foundry[0].account_id, subresource_names = ["account"], dns_zone_names = ["privatelink.cognitiveservices.azure.com", "privatelink.openai.azure.com", "privatelink.services.ai.azure.com"] }
  })
  dns_zone_names = setunion(
    toset(["privatelink.vaultcore.azure.net", "privatelink.blob.core.windows.net", "privatelink.monitor.azure.com", "privatelink.oms.opinsights.azure.com", "privatelink.ods.opinsights.azure.com", "privatelink.agentsvc.azure-automation.net"]),
    var.foundry == null ? toset([]) : toset(["privatelink.cognitiveservices.azure.com", "privatelink.openai.azure.com", "privatelink.services.ai.azure.com"])
  )
}
module "identity" {
  source              = "./modules/identity"
  name                = local.name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = local.tags
  # Retain legacy resource addresses while allowing independent least-privilege grants.
  assignments = merge(
    var.grant_workload_data_access || var.workload_data_access.key_vault_secret_read ? {
      secrets = { scope = module.security.key_vault_id, role_definition_name = "Key Vault Secrets User" }
    } : {},
    var.grant_workload_data_access || var.workload_data_access.storage_blob_read ? {
      blobs = { scope = module.security.storage_account_id, role_definition_name = "Storage Blob Data Reader" }
    } : {},
    var.grant_workload_data_access || var.workload_data_access.telemetry_publish ? {
      telemetry = { scope = module.monitoring.application_insights_id, role_definition_name = "Monitoring Metrics Publisher" }
    } : {}
  )
}

module "foundry" {
  count                       = var.foundry == null ? 0 : 1
  source                      = "./modules/foundry"
  configuration               = var.foundry
  subscription_id             = var.subscription_id
  resource_group_name         = azurerm_resource_group.this.name
  location                    = var.location
  approved_locations          = var.approved_locations
  tags                        = local.tags
  key_vault_id                = module.security.key_vault_id
  storage_account_id          = module.security.storage_account_id
  openai_inference_principals = var.foundry_grant_workload_openai_access ? { workload = module.identity.principal_id } : {}
}
