resource "azurerm_log_analytics_workspace" "this" {
  name                            = "law-${var.name}"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  sku                             = "PerGB2018"
  retention_in_days               = var.retention_in_days
  internet_ingestion_access_type  = "Disabled"
  internet_query_access_type      = "Disabled"
  local_authentication_enabled    = false
  allow_resource_only_permissions = true
  tags                            = var.tags
}
resource "azurerm_application_insights" "this" {
  name                         = "appi-${var.name}"
  location                     = var.location
  resource_group_name          = var.resource_group_name
  application_type             = "web"
  workspace_id                 = azurerm_log_analytics_workspace.this.id
  internet_ingestion_enabled   = false
  internet_query_enabled       = false
  local_authentication_enabled = false
  tags                         = var.tags
}
resource "azurerm_monitor_private_link_scope" "this" {
  name                  = "ampls-${var.name}"
  resource_group_name   = var.resource_group_name
  ingestion_access_mode = "PrivateOnly"
  query_access_mode     = "PrivateOnly"
  tags                  = var.tags
}
resource "azurerm_monitor_private_link_scoped_service" "workspace" {
  name                = "law-link"
  resource_group_name = var.resource_group_name
  scope_name          = azurerm_monitor_private_link_scope.this.name
  linked_resource_id  = azurerm_log_analytics_workspace.this.id
}
resource "azurerm_monitor_private_link_scoped_service" "insights" {
  name                = "appi-link"
  resource_group_name = var.resource_group_name
  scope_name          = azurerm_monitor_private_link_scope.this.name
  linked_resource_id  = azurerm_application_insights.this.id
}
resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each                   = var.diagnostic_targets
  name                       = "diag-${each.key}"
  target_resource_id         = each.value.resource_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  dynamic "enabled_log" {
    for_each = each.value.log_categories
    content { category = enabled_log.value }
  }
  dynamic "enabled_log" {
    for_each = each.value.log_category_groups
    content { category_group = enabled_log.value }
  }
  dynamic "enabled_metric" {
    for_each = each.value.metric_categories
    content { category = enabled_metric.value }
  }
}
