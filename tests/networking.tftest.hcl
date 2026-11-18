mock_provider "azurerm" {}
run "network_isolation" {
  command = plan
  module { source = "./modules/networking" }
  variables {
    name                = "test"
    resource_group_name = "rg-test"
    location            = "eastus2"
    tags                = {}
    address_space       = ["10.40.0.0/16"]
    workload_prefixes   = ["10.40.1.0/24"]
    endpoint_prefixes   = ["10.40.2.0/24"]
    trusted_prefixes    = ["10.50.0.0/24"]
  }
  assert {
    condition     = azurerm_subnet.endpoints.private_endpoint_network_policies == "Enabled" && !azurerm_subnet.endpoints.default_outbound_access_enabled
    error_message = "Endpoint NSG enforcement must be enabled and default outbound disabled."
  }
  assert {
    condition     = alltrue([for k in ["workload_deny_in", "workload_deny_out", "endpoints_deny_in", "endpoints_deny_out"] : azurerm_network_security_rule.this[k].access == "Deny" && azurerm_network_security_rule.this[k].priority == 4096])
    error_message = "Explicit deny rules must override the built-in VNet and Internet allowances."
  }
  assert {
    condition     = azurerm_network_security_rule.this["endpoints_https"].destination_port_range == "443" && azurerm_network_security_rule.this["workload_https"].source_address_prefix == "10.50.0.0/24"
    error_message = "Trusted access must be HTTPS and limited to approved source ranges."
  }
  assert {
    condition     = length(azurerm_private_dns_zone.this) == 6 && alltrue([for v in azurerm_private_dns_zone_virtual_network_link.this : !v.registration_enabled])
    error_message = "Service DNS zones must be linked without VM auto-registration."
  }
}
run "reject_world_trust" {
  command = plan
  module { source = "./modules/networking" }
  variables {
    name                = "test"
    resource_group_name = "rg-test"
    location            = "eastus2"
    tags                = {}
    address_space       = ["10.40.0.0/16"]
    workload_prefixes   = ["10.40.1.0/24"]
    endpoint_prefixes   = ["10.40.2.0/24"]
    trusted_prefixes    = ["0.0.0.0/0"]
  }
  expect_failures = [var.trusted_prefixes]
}

run "reject_unowned_private_dns" {
  command = plan
  module { source = "./modules/networking" }
  variables {
    name                = "test"
    resource_group_name = "rg-test"
    location            = "eastus2"
    tags                = {}
    address_space       = ["10.40.0.0/16"]
    workload_prefixes   = ["10.40.1.0/24"]
    endpoint_prefixes   = ["10.40.2.0/24"]
    private_endpoints = { vault = {
      resource_id       = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test"
      subresource_names = ["vault"]
      dns_zone_names    = ["privatelink.not-owned.example"]
    } }
  }
  expect_failures = [var.private_endpoints]
}

run "reject_empty_endpoint_group" {
  command = plan
  module { source = "./modules/networking" }
  variables {
    name                = "test"
    resource_group_name = "rg-test"
    location            = "eastus2"
    tags                = {}
    address_space       = ["10.40.0.0/16"]
    workload_prefixes   = ["10.40.1.0/24"]
    endpoint_prefixes   = ["10.40.2.0/24"]
    private_endpoints = { vault = {
      resource_id       = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test"
      subresource_names = []
      dns_zone_names    = ["privatelink.vaultcore.azure.net"]
    } }
  }
  expect_failures = [var.private_endpoints]
}

run "service_groups_and_shared_dns_owner" {
  command = plan
  module { source = "./modules/networking" }
  variables {
    name                = "test"
    resource_group_name = "rg-test"
    location            = "eastus2"
    tags                = {}
    address_space       = ["10.40.0.0/16"]
    workload_prefixes   = ["10.40.1.0/24"]
    endpoint_prefixes   = ["10.40.2.0/24"]
    dns_zone_names      = ["privatelink.vaultcore.azure.net", "privatelink.blob.core.windows.net", "privatelink.monitor.azure.com", "privatelink.oms.opinsights.azure.com", "privatelink.ods.opinsights.azure.com", "privatelink.agentsvc.azure-automation.net", "privatelink.cognitiveservices.azure.com", "privatelink.openai.azure.com", "privatelink.services.ai.azure.com"]
    private_endpoints = {
      vault   = { resource_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test", subresource_names = ["vault"], dns_zone_names = ["privatelink.vaultcore.azure.net"] }
      blob    = { resource_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/sttest", subresource_names = ["blob"], dns_zone_names = ["privatelink.blob.core.windows.net"] }
      monitor = { resource_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-test/providers/Microsoft.Insights/privateLinkScopes/ampls-test", subresource_names = ["azuremonitor"], dns_zone_names = ["privatelink.monitor.azure.com", "privatelink.oms.opinsights.azure.com", "privatelink.ods.opinsights.azure.com", "privatelink.agentsvc.azure-automation.net", "privatelink.blob.core.windows.net"] }
      foundry = { resource_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-test/providers/Microsoft.CognitiveServices/accounts/foundry-test", subresource_names = ["account"], dns_zone_names = ["privatelink.cognitiveservices.azure.com", "privatelink.openai.azure.com", "privatelink.services.ai.azure.com"] }
    }
  }
  assert {
    condition     = alltrue([for key, group in { vault = "vault", blob = "blob", monitor = "azuremonitor", foundry = "account" } : azurerm_private_endpoint.this[key].private_service_connection[0].subresource_names == tolist([group]) && !azurerm_private_endpoint.this[key].private_service_connection[0].is_manual_connection])
    error_message = "Each service must use its documented endpoint group without changing resource ownership."
  }
  assert {
    condition     = length(azurerm_private_dns_zone.this) == 9 && length(azurerm_private_dns_zone_virtual_network_link.this) == 9 && length(azurerm_private_endpoint.this["monitor"].private_dns_zone_group[0].private_dns_zone_ids) == 5 && length(azurerm_private_endpoint.this["foundry"].private_dns_zone_group[0].private_dns_zone_ids) == 3
    error_message = "Blob and AMPLS must share one centrally linked blob zone, with all service-specific zone groups retained."
  }
}
