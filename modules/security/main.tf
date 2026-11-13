resource "azurerm_key_vault" "this" {
  lifecycle { prevent_destroy = true }
  name                            = var.key_vault_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  tenant_id                       = var.tenant_id
  sku_name                        = "standard"
  rbac_authorization_enabled      = true
  public_network_access_enabled   = false
  purge_protection_enabled        = true
  soft_delete_retention_days      = 90
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
  network_acls {
    bypass         = "None"
    default_action = "Deny"
  }
  tags = var.tags
}
resource "azurerm_storage_account" "this" {
  lifecycle { prevent_destroy = true }
  name                              = var.storage_account_name
  location                          = var.location
  resource_group_name               = var.resource_group_name
  account_kind                      = "StorageV2"
  account_tier                      = "Standard"
  account_replication_type          = var.storage_replication_type
  public_network_access             = "Disabled"
  shared_access_key_enabled         = false
  default_to_oauth_authentication   = true
  allow_nested_items_to_be_public   = false
  cross_tenant_replication_enabled  = false
  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"
  infrastructure_encryption_enabled = true
  local_user_enabled                = false
  network_rules {
    default_action = "Deny"
    bypass         = ["None"]
  }
  blob_properties {
    versioning_enabled = true
    delete_retention_policy { days = 30 }
    container_delete_retention_policy { days = 30 }
  }
  tags = var.tags
}
resource "azurerm_resource_group_policy_assignment" "this" {
  for_each             = var.policy_assignments
  name                 = each.key
  resource_group_id    = var.resource_group_id
  policy_definition_id = each.value.policy_definition_id
  description          = each.value.description
  parameters           = each.value.parameters
  enforce              = true
}
