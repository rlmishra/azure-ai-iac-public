output "vnet_id" { value = azurerm_virtual_network.this.id }
output "workload_subnet_id" { value = azurerm_subnet.workload.id }
output "endpoint_subnet_id" { value = azurerm_subnet.endpoints.id }
output "private_endpoint_ids" { value = { for k, v in azurerm_private_endpoint.this : k => v.id } }
output "dns_zone_ids" { value = { for k, v in azurerm_private_dns_zone.this : k => v.id } }
output "default_outbound_access_enabled" { value = azurerm_subnet.workload.default_outbound_access_enabled }
