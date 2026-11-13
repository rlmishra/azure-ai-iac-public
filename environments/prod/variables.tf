variable "subscription_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "Supply the approved subscription UUID."
  }
}
variable "tenant_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "Supply the Entra tenant UUID."
  }
}
variable "name" {
  description = "Short workload identifier, for example aicore."
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,15}$", var.name))
    error_message = "Name must be 3-16 lowercase letters, digits or hyphens, starting with a letter."
  }
}
variable "environment" {
  default = "prod"
  type    = string
  validation {
    condition     = var.environment == "prod"
    error_message = "Environment must be dev, test or prod."
  }
}
variable "location" {
  type = string
}
variable "approved_locations" {
  type = set(string)
  validation {
    condition     = length(var.approved_locations) > 0 && contains(var.approved_locations, var.location)
    error_message = "Location must be in the explicitly approved locations set."
  }
}
variable "tags" {
  type = map(string)
  validation {
    condition     = alltrue([for k in ["owner", "cost_center", "data_classification", "application"] : try(length(trimspace(var.tags[k])) > 0, false)])
    error_message = "Nonempty owner, cost_center, data_classification and application tags are required."
  }
}
variable "address_space" {
  type = list(string)
  validation {
    condition     = length(var.address_space) > 0 && alltrue([for p in var.address_space : can(cidrnetmask(p))])
    error_message = "Provide valid IPv4 VNet CIDRs."
  }
}
variable "workload_prefixes" {
  type = list(string)
  validation {
    condition     = length(var.workload_prefixes) > 0 && alltrue([for p in var.workload_prefixes : can(cidrnetmask(p))])
    error_message = "Provide valid IPv4 workload subnet CIDRs."
  }
  validation {
    condition     = alltrue([for s in var.workload_prefixes : anytrue([for v in var.address_space : try(tonumber(split("/", s)[1]) >= tonumber(split("/", v)[1]) && cidrhost("${cidrhost(s, 0)}/${split("/", v)[1]}", 0) == cidrhost(v, 0), false)])])
    error_message = "Every workload subnet must be inside an allocated VNet CIDR."
  }
}
variable "endpoint_prefixes" {
  type = list(string)
  validation {
    condition     = length(var.endpoint_prefixes) > 0 && alltrue([for p in var.endpoint_prefixes : can(cidrnetmask(p)) && try(tonumber(split("/", p)[1]) <= 27, false)])
    error_message = "Private endpoint subnet requires an IPv4 /27 or larger allocation."
  }
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
}
variable "dns_servers" {
  type    = list(string)
  default = []
}
variable "key_vault_name" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,22}[a-z0-9]$", var.key_vault_name)) && !strcontains(var.key_vault_name, "--")
    error_message = "Key Vault name must be 3-24 characters, start with a letter, end alphanumeric, without consecutive hyphens."
  }
}
variable "storage_account_name" {
  type = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 lowercase alphanumeric characters."
  }
}
variable "storage_replication_type" {
  type    = string
  default = "ZRS"
}
variable "retention_in_days" {
  type    = number
  default = 90
}
variable "grant_workload_data_access" {
  description = "Opt in only after application access review; grants secrets read, blob read and telemetry publishing."
  type        = bool
  default     = false
}
variable "policy_assignments" {
  type    = map(object({ policy_definition_id = string, parameters = optional(string, "{}"), description = optional(string, "Enterprise landing-zone guardrail") }))
  default = {}
}
