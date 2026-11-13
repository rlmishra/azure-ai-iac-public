mock_provider "azurerm" {}
variables {
  name                = "test"
  resource_group_name = "rg-test"
  location            = "eastus2"
  tags                = {}
}
run "reject_privileged_role" {
  command = plan
  module { source = "./modules/identity" }
  variables {
    assignments = { excessive = { scope = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test", role_definition_name = "Owner", principal_id = "33333333-3333-3333-3333-333333333333" } }
  }
  expect_failures = [var.assignments]
}
run "reject_broad_scope" {
  command = plan
  module { source = "./modules/identity" }
  variables {
    assignments = { excessive = { scope = "/subscriptions/11111111-1111-1111-1111-111111111111", role_definition_name = "Key Vault Secrets User", principal_id = "33333333-3333-3333-3333-333333333333" } }
  }
  expect_failures = [var.assignments]
}
