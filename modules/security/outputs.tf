output "key_vault_id" { value = azurerm_key_vault.this.id }
output "key_vault_uri" { value = azurerm_key_vault.this.vault_uri }
output "storage_account_id" { value = azurerm_storage_account.this.id }
output "blob_service_id" { value = "${azurerm_storage_account.this.id}/blobServices/default" }
output "storage_blob_endpoint" { value = azurerm_storage_account.this.primary_blob_endpoint }
output "posture" {
  value = {
    vault_public_access               = azurerm_key_vault.this.public_network_access_enabled
    vault_rbac                        = azurerm_key_vault.this.rbac_authorization_enabled
    vault_purge_protection            = azurerm_key_vault.this.purge_protection_enabled
    storage_public_access             = azurerm_storage_account.this.public_network_access
    storage_shared_keys               = azurerm_storage_account.this.shared_access_key_enabled
    storage_infrastructure_encryption = azurerm_storage_account.this.infrastructure_encryption_enabled
  }
}
