output "workspace_id" { value = azurerm_log_analytics_workspace.this.id }
output "application_insights_id" { value = azurerm_application_insights.this.id }
output "application_insights_connection_string" {
  value     = azurerm_application_insights.this.connection_string
  sensitive = true
}
output "private_link_scope_id" {
  value      = azurerm_monitor_private_link_scope.this.id
  depends_on = [azurerm_monitor_private_link_scoped_service.workspace, azurerm_monitor_private_link_scoped_service.insights]
}
output "posture" {
  value = {
    ingestion       = azurerm_log_analytics_workspace.this.internet_ingestion_access_type
    query           = azurerm_log_analytics_workspace.this.internet_query_access_type
    local_auth      = azurerm_log_analytics_workspace.this.local_authentication_enabled
    scope_ingestion = azurerm_monitor_private_link_scope.this.ingestion_access_mode
    scope_query     = azurerm_monitor_private_link_scope.this.query_access_mode
  }
}
