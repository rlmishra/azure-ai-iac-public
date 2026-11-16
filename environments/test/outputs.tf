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

output "foundry" {
  description = "Non-secret Foundry metadata for applications/Phase 3; null when disabled. Project endpoint map keys are provider/service defined."
  value = var.foundry == null ? null : {
    account_id       = module.foundry[0].account_id
    account_endpoint = module.foundry[0].account_endpoint
    openai_endpoint  = module.foundry[0].openai_endpoint
    projects         = module.foundry[0].projects
    deployments      = module.foundry[0].deployments
    posture          = module.foundry[0].posture
  }
}
