output "id" { value = azurerm_user_assigned_identity.workload.id }
output "client_id" { value = azurerm_user_assigned_identity.workload.client_id }
output "principal_id" { value = azurerm_user_assigned_identity.workload.principal_id }
output "role_assignment_ids" { value = { for k, v in azurerm_role_assignment.this : k => v.id } }
