resource "azurerm_user_assigned_identity" "workload" {
  name                = "id-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}
resource "azurerm_role_assignment" "this" {
  for_each                         = var.assignments
  scope                            = each.value.scope
  role_definition_name             = each.value.role_definition_name
  principal_id                     = coalesce(each.value.principal_id, azurerm_user_assigned_identity.workload.principal_id)
  principal_type                   = each.value.principal_type
  skip_service_principal_aad_check = each.value.principal_type == "ServicePrincipal"
}
