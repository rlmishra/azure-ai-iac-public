output "id" { value = azurerm_user_assigned_identity.workload.id }
output "client_id" { value = azurerm_user_assigned_identity.workload.client_id }
output "principal_id" { value = azurerm_user_assigned_identity.workload.principal_id }
output "role_assignment_ids" { value = { for k, v in azurerm_role_assignment.this : k => v.id } }

output "access_grants" {
  description = "Nonsecret effective resource-scoped workload grants; does not prove host attachment or runtime authorization."
  value = { for k, a in azurerm_role_assignment.this : k => {
    scope                = a.scope
    role_definition_name = a.role_definition_name
    principal_id         = a.principal_id
  } }
}
