locals {
  role_base = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions"
  # Microsoft documents these GUIDs as stable across the Foundry role-name rollout.
  foundry_user_role_id = "${local.role_base}/53ca6127-db72-4b80-b1b0-d745d6d5456d"
  openai_user_role_id  = "${local.role_base}/5e0bd9bd-7b93-4f28-af87-19fc36ad61bd"
  project_users = merge({}, [for name, p in var.configuration.projects : {
    for label, user in p.users : "${name}/${label}" => merge(user, { project = name })
  }]...)
  approved_deployments = { for name, d in var.configuration.deployments : name => d
    if var.configuration.enable_model_deployments && contains(keys(var.configuration.approved_models), d.approval_id)
  }
}
resource "azurerm_cognitive_account" "this" {
  name                               = var.configuration.account_name
  resource_group_name                = var.resource_group_name
  location                           = var.location
  kind                               = "AIServices"
  sku_name                           = "S0"
  custom_subdomain_name              = var.configuration.custom_subdomain_name
  project_management_enabled         = true
  public_network_access_enabled      = false
  local_auth_enabled                 = false
  outbound_network_access_restricted = true
  identity { type = "SystemAssigned" }
  network_acls {
    default_action = "Deny"
    bypass         = "None"
  }
  tags = var.tags
  lifecycle { prevent_destroy = true }
}
resource "azurerm_cognitive_account_project" "this" {
  for_each             = var.configuration.projects
  name                 = each.key
  cognitive_account_id = azurerm_cognitive_account.this.id
  location             = var.location
  description          = each.value.description
  display_name         = each.value.display_name
  identity { type = "SystemAssigned" }
  tags = var.tags
  lifecycle { prevent_destroy = true }
}
resource "azurerm_cognitive_deployment" "this" {
  for_each               = local.approved_deployments
  name                   = each.key
  cognitive_account_id   = azurerm_cognitive_account.this.id
  version_upgrade_option = "NoAutoUpgrade"
  rai_policy_name        = each.value.rai_policy_name
  model {
    format  = var.configuration.approved_models[each.value.approval_id].format
    name    = var.configuration.approved_models[each.value.approval_id].name
    version = var.configuration.approved_models[each.value.approval_id].version
  }
  sku {
    name     = each.value.sku_name
    capacity = each.value.capacity
  }
}
resource "azurerm_role_assignment" "project_account" {
  for_each                         = { for name, p in var.configuration.projects : name => p if p.grant_account_access }
  scope                            = azurerm_cognitive_account.this.id
  role_definition_id               = local.foundry_user_role_id
  principal_id                     = azurerm_cognitive_account_project.this[each.key].identity[0].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
resource "azurerm_role_assignment" "project_user" {
  for_each                         = local.project_users
  scope                            = azurerm_cognitive_account_project.this[each.value.project].id
  role_definition_id               = local.foundry_user_role_id
  principal_id                     = each.value.principal_id
  principal_type                   = each.value.principal_type
  skip_service_principal_aad_check = each.value.principal_type == "ServicePrincipal"
}
resource "azurerm_role_assignment" "openai_inference" {
  for_each                         = var.openai_inference_principals
  scope                            = azurerm_cognitive_account.this.id
  role_definition_id               = local.openai_user_role_id
  principal_id                     = each.value
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
resource "azurerm_role_assignment" "project_secrets" {
  for_each                         = { for name, p in var.configuration.projects : name => p if p.key_vault_secret_read }
  scope                            = var.key_vault_id
  role_definition_name             = "Key Vault Secrets User"
  principal_id                     = azurerm_cognitive_account_project.this[each.key].identity[0].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
resource "azurerm_role_assignment" "project_blobs" {
  for_each                         = { for name, p in var.configuration.projects : name => p if p.storage_blob_read }
  scope                            = var.storage_account_id
  role_definition_name             = "Storage Blob Data Reader"
  principal_id                     = azurerm_cognitive_account_project.this[each.key].identity[0].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
