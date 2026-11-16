output "account_id" { value = azurerm_cognitive_account.this.id }
output "account_endpoint" { value = azurerm_cognitive_account.this.endpoint }
output "openai_endpoint" {
  description = "Public Azure OpenAI-compatible base URL; resolve through Private Link. Does not specify a model API route or api-version."
  value       = "https://${azurerm_cognitive_account.this.custom_subdomain_name}.openai.azure.com/"
}
output "account_principal_id" { value = azurerm_cognitive_account.this.identity[0].principal_id }
output "projects" {
  value = { for name, p in azurerm_cognitive_account_project.this : name => {
    id           = p.id
    principal_id = p.identity[0].principal_id
    endpoints    = p.endpoints
  } }
}
output "deployments" {
  value = { for name, d in azurerm_cognitive_deployment.this : name => {
    id                     = d.id
    model                  = d.model[0]
    sku                    = d.sku[0].name
    capacity               = d.sku[0].capacity
    version_upgrade_option = d.version_upgrade_option
  } }
}
output "posture" {
  value = {
    kind                   = azurerm_cognitive_account.this.kind
    project_management     = azurerm_cognitive_account.this.project_management_enabled
    public_network_access  = azurerm_cognitive_account.this.public_network_access_enabled
    local_auth             = azurerm_cognitive_account.this.local_auth_enabled
    outbound_restricted    = azurerm_cognitive_account.this.outbound_network_access_restricted
    network_default_action = azurerm_cognitive_account.this.network_acls[0].default_action
    network_bypass         = azurerm_cognitive_account.this.network_acls[0].bypass
    identity_type          = azurerm_cognitive_account.this.identity[0].type
    deployment_count       = length(azurerm_cognitive_deployment.this)
    role_assignment_count  = length(azurerm_role_assignment.project_account) + length(azurerm_role_assignment.project_user) + length(azurerm_role_assignment.openai_inference) + length(azurerm_role_assignment.project_secrets) + length(azurerm_role_assignment.project_blobs)
  }
}
