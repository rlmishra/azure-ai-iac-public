output "resource_group_id" { value = azurerm_resource_group.this.id }
output "vnet_id" { value = module.networking.vnet_id }
output "workload_subnet_id" { value = module.networking.workload_subnet_id }
output "private_endpoint_ids" { value = module.networking.private_endpoint_ids }
output "workload_identity" { value = { id = module.identity.id, client_id = module.identity.client_id, principal_id = module.identity.principal_id } }
output "key_vault_uri" { value = module.security.key_vault_uri }
output "storage_blob_endpoint" { value = module.security.storage_blob_endpoint }
output "workspace_id" { value = module.monitoring.workspace_id }
output "application_insights_connection_string" {
  value     = module.monitoring.application_insights_connection_string
  sensitive = true
}
output "security_posture" { value = module.security.posture }
output "monitoring_posture" { value = module.monitoring.posture }
output "tags" { value = azurerm_resource_group.this.tags }
