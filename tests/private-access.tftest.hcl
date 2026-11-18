mock_provider "azurerm" {}
run "vault_and_blob_have_no_public_or_key_fallback" {
  command = plan
  module { source = "./modules/security" }
  variables {
    name                 = "test"
    resource_group_name  = "rg-test"
    resource_group_id    = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-test"
    location             = "eastus2"
    tags                 = {}
    tenant_id            = "22222222-2222-2222-2222-222222222222"
    key_vault_name       = "kv-private-test"
    storage_account_name = "stprivatetest"
  }
  assert {
    condition     = !azurerm_key_vault.this.public_network_access_enabled && azurerm_key_vault.this.rbac_authorization_enabled && azurerm_key_vault.this.network_acls[0].bypass == "None" && azurerm_key_vault.this.network_acls[0].default_action == "Deny"
    error_message = "Vault access must not fall back to public access, access policies or trusted-service bypass."
  }
  assert {
    condition     = azurerm_storage_account.this.public_network_access == "Disabled" && !azurerm_storage_account.this.shared_access_key_enabled && !azurerm_storage_account.this.local_user_enabled && azurerm_storage_account.this.default_to_oauth_authentication && azurerm_storage_account.this.network_rules[0].bypass == toset(["None"])
    error_message = "Storage must retain public/key/local-user denial and no trusted-service bypass."
  }
}
run "monitoring_requires_entra_and_private_scope" {
  command = plan
  module { source = "./modules/monitoring" }
  variables {
    name                = "test"
    resource_group_name = "rg-test"
    location            = "eastus2"
    tags                = {}
  }
  assert {
    condition     = !azurerm_application_insights.this.local_authentication_enabled && !azurerm_application_insights.this.internet_ingestion_enabled && !azurerm_application_insights.this.internet_query_enabled && !azurerm_log_analytics_workspace.this.local_authentication_enabled && azurerm_monitor_private_link_scope.this.ingestion_access_mode == "PrivateOnly" && azurerm_monitor_private_link_scope.this.query_access_mode == "PrivateOnly"
    error_message = "Both Insights and LAW must reject local authentication and preserve private AMPLS modes."
  }
}
