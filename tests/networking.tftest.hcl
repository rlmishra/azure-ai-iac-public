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
