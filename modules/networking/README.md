# networking

VNet, workload/endpoint subnets, explicit NSGs, linked private zones and configurable private endpoints.

The caller supplies approved address allocation, routes and DNS forwarding. NSGs permit only DNS and private endpoint HTTPS by default. Supply trusted_prefixes for private runner access; no public ingress or NAT is created. Existing centralized DNS zones must be imported or handled through an ownership adaptation before deploying duplicates.

Requires Terraform 1.17.2 and AzureRM 5.13.0. Configure the provider in the calling root. Inputs are typed and documented in `variables.tf`; outputs are in `outputs.tf`. See the repository root and environment roots for complete executable compositions.

Inputs: `name`, `resource_group_name`, `location`, `tags`, `address_space`, `workload_prefixes`, `endpoint_prefixes`, `trusted_prefixes`, `dns_servers`, `private_endpoints`, `dns_zone_names`.

Outputs: `vnet_id`, `workload_subnet_id`, `endpoint_subnet_id`, `private_endpoint_ids`, `dns_zone_ids`, `default_outbound_access_enabled`.
