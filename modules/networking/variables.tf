variable "name" {
  type = string
}
variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
}
variable "tags" {
  type = map(string)
}
variable "address_space" {
  type = list(string)
}
variable "workload_prefixes" {
  type = list(string)
  validation {
    condition     = alltrue([for s in var.workload_prefixes : anytrue([for v in var.address_space : try(tonumber(split("/", s)[1]) >= tonumber(split("/", v)[1]) && cidrhost("${cidrhost(s, 0)}/${split("/", v)[1]}", 0) == cidrhost(v, 0), false)])])
    error_message = "Every workload subnet must be inside an allocated VNet CIDR."
  }
}
variable "endpoint_prefixes" {
  type = list(string)
  validation {
    condition     = alltrue([for s in var.endpoint_prefixes : anytrue([for v in var.address_space : try(tonumber(split("/", s)[1]) >= tonumber(split("/", v)[1]) && cidrhost("${cidrhost(s, 0)}/${split("/", v)[1]}", 0) == cidrhost(v, 0), false)])])
    error_message = "Every endpoint subnet must be inside an allocated VNet CIDR."
  }
  validation {
    condition     = alltrue(flatten([for a in var.workload_prefixes : [for b in var.endpoint_prefixes : try(cidrhost("${cidrhost(a, 0)}/${min(tonumber(split("/", a)[1]), tonumber(split("/", b)[1]))}", 0) != cidrhost("${cidrhost(b, 0)}/${min(tonumber(split("/", a)[1]), tonumber(split("/", b)[1]))}", 0), false)]]))
    error_message = "Workload and endpoint subnet address ranges must not overlap."
  }
}
variable "trusted_prefixes" {
  type    = list(string)
  default = []
  validation {
    condition     = alltrue([for p in var.trusted_prefixes : can(cidrnetmask(p)) && try(tonumber(split("/", p)[1]) >= 8, false)])
    error_message = "Trusted networks must be explicit IPv4 CIDRs with prefix length at least 8."
  }
}
variable "dns_servers" {
  type    = list(string)
  default = []
}
variable "private_endpoints" {
  description = "Stable keys, Azure resource IDs, service subresources and DNS zones. All zones must be provisioned in dns_zone_names."
  type = map(object({
    resource_id       = string
    subresource_names = list(string)
    dns_zone_names    = set(string)
  }))
  default = {}
}
variable "dns_zone_names" {
  type    = set(string)
  default = ["privatelink.vaultcore.azure.net", "privatelink.blob.core.windows.net", "privatelink.monitor.azure.com", "privatelink.oms.opinsights.azure.com", "privatelink.ods.opinsights.azure.com", "privatelink.agentsvc.azure-automation.net"]
}
