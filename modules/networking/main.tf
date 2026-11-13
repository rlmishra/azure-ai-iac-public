resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  tags                = var.tags
}
resource "azurerm_subnet" "workload" {
  name                            = "snet-workload"
  resource_group_name             = var.resource_group_name
  virtual_network_name            = azurerm_virtual_network.this.name
  address_prefixes                = var.workload_prefixes
  default_outbound_access_enabled = false
}
resource "azurerm_subnet" "endpoints" {
  name                              = "snet-private-endpoints"
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.this.name
  address_prefixes                  = var.endpoint_prefixes
  default_outbound_access_enabled   = false
  private_endpoint_network_policies = "Enabled"
}
resource "azurerm_network_security_group" "this" {
  for_each            = toset(["workload", "endpoints"])
  name                = "nsg-${var.name}-${each.key}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}
locals {
  rules = merge({
    workload_dns           = { nsg = "workload", priority = 100, direction = "Outbound", access = "Allow", protocol = "*", sources = ["*"], destinations = length(var.dns_servers) > 0 ? var.dns_servers : ["AzurePlatformDNS"], port = "53" }
    workload_private_https = { nsg = "workload", priority = 110, direction = "Outbound", access = "Allow", protocol = "Tcp", sources = ["*"], destinations = var.endpoint_prefixes, port = "443" }
    endpoints_https        = { nsg = "endpoints", priority = 100, direction = "Inbound", access = "Allow", protocol = "Tcp", sources = concat(var.workload_prefixes, var.trusted_prefixes), destinations = var.endpoint_prefixes, port = "443" }
    workload_deny_in       = { nsg = "workload", priority = 4096, direction = "Inbound", access = "Deny", protocol = "*", sources = ["*"], destinations = ["*"], port = "*" }
    workload_deny_out      = { nsg = "workload", priority = 4096, direction = "Outbound", access = "Deny", protocol = "*", sources = ["*"], destinations = ["*"], port = "*" }
    endpoints_deny_in      = { nsg = "endpoints", priority = 4096, direction = "Inbound", access = "Deny", protocol = "*", sources = ["*"], destinations = ["*"], port = "*" }
    endpoints_deny_out     = { nsg = "endpoints", priority = 4096, direction = "Outbound", access = "Deny", protocol = "*", sources = ["*"], destinations = ["*"], port = "*" }
    }, length(var.trusted_prefixes) > 0 ? {
    workload_https = { nsg = "workload", priority = 100, direction = "Inbound", access = "Allow", protocol = "Tcp", sources = var.trusted_prefixes, destinations = var.workload_prefixes, port = "443" }
  } : {})
}
resource "azurerm_network_security_rule" "this" {
  for_each                     = local.rules
  name                         = each.key
  priority                     = each.value.priority
  direction                    = each.value.direction
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_port_range            = "*"
  destination_port_range       = each.value.port
  source_address_prefix        = length(each.value.sources) == 1 ? each.value.sources[0] : null
  source_address_prefixes      = length(each.value.sources) > 1 ? each.value.sources : null
  destination_address_prefix   = length(each.value.destinations) == 1 ? each.value.destinations[0] : null
  destination_address_prefixes = length(each.value.destinations) > 1 ? each.value.destinations : null
  resource_group_name          = var.resource_group_name
  network_security_group_name  = azurerm_network_security_group.this[each.value.nsg].name
}
resource "azurerm_subnet_network_security_group_association" "workload" {
  subnet_id                 = azurerm_subnet.workload.id
  network_security_group_id = azurerm_network_security_group.this["workload"].id
}
resource "azurerm_subnet_network_security_group_association" "endpoints" {
  subnet_id                 = azurerm_subnet.endpoints.id
  network_security_group_id = azurerm_network_security_group.this["endpoints"].id
}
resource "azurerm_private_dns_zone" "this" {
  for_each            = var.dns_zone_names
  name                = each.key
  resource_group_name = var.resource_group_name
  tags                = var.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each             = var.dns_zone_names
  name                 = "link-${var.name}"
  private_dns_zone_id  = azurerm_private_dns_zone.this[each.key].id
  virtual_network_id   = azurerm_virtual_network.this.id
  registration_enabled = false
  tags                 = var.tags
}
resource "azurerm_private_endpoint" "this" {
  for_each            = var.private_endpoints
  name                = "pe-${var.name}-${each.key}"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = azurerm_subnet.endpoints.id
  tags                = var.tags
  private_service_connection {
    name                           = "psc-${each.key}"
    private_connection_resource_id = each.value.resource_id
    subresource_names              = each.value.subresource_names
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [for zone in each.value.dns_zone_names : azurerm_private_dns_zone.this[zone].id]
  }
  depends_on = [azurerm_subnet_network_security_group_association.endpoints, azurerm_private_dns_zone_virtual_network_link.this]
}
