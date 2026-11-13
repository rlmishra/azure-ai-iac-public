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
  diagnostic_targets = {
    vault   = { resource_id = module.security.key_vault_id, log_category_groups = ["audit"], metric_categories = ["AllMetrics"] }
    storage = { resource_id = module.security.storage_account_id, metric_categories = ["Transaction"] }
    blob    = { resource_id = module.security.blob_service_id, log_categories = ["StorageRead", "StorageWrite", "StorageDelete"], metric_categories = ["Transaction"] }
  }
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
  private_endpoints = {
    vault   = { resource_id = module.security.key_vault_id, subresource_names = ["vault"], dns_zone_names = ["privatelink.vaultcore.azure.net"] }
    blob    = { resource_id = module.security.storage_account_id, subresource_names = ["blob"], dns_zone_names = ["privatelink.blob.core.windows.net"] }
    monitor = { resource_id = module.monitoring.private_link_scope_id, subresource_names = ["azuremonitor"], dns_zone_names = ["privatelink.monitor.azure.com", "privatelink.oms.opinsights.azure.com", "privatelink.ods.opinsights.azure.com", "privatelink.agentsvc.azure-automation.net", "privatelink.blob.core.windows.net"] }
  }
}
module "identity" {
  source              = "./modules/identity"
  name                = local.name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = local.tags
  assignments = var.grant_workload_data_access ? {
    secrets   = { scope = module.security.key_vault_id, role_definition_name = "Key Vault Secrets User" }
    blobs     = { scope = module.security.storage_account_id, role_definition_name = "Storage Blob Data Reader" }
    telemetry = { scope = module.monitoring.application_insights_id, role_definition_name = "Monitoring Metrics Publisher" }
  } : {}
}
