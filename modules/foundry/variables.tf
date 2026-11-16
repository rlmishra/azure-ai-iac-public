variable "configuration" {
  description = "Explicit account/project configuration and approved model catalog. Catalog entries are organizational approvals, not Azure availability claims."
  type = object({
    account_name          = string
    custom_subdomain_name = string
    projects = map(object({
      description           = optional(string)
      display_name          = optional(string)
      grant_account_access  = optional(bool, false)
      key_vault_secret_read = optional(bool, false)
      storage_blob_read     = optional(bool, false)
      users = optional(map(object({
        principal_id   = string
        principal_type = optional(string, "ServicePrincipal")
      })), {})
    }))
    enable_model_deployments = optional(bool, false)
    approved_models = optional(map(object({
      format            = string
      name              = string
      version           = string
      permitted_regions = set(string)
      permitted_skus    = set(string)
      max_capacity      = number
    })), {})
    deployments = optional(map(object({
      approval_id     = string
      sku_name        = string
      capacity        = number
      rai_policy_name = optional(string)
    })), {})
  })
  nullable = false
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{1,62}[a-zA-Z0-9]$", var.configuration.account_name)) && can(regex("^[a-z0-9][a-z0-9-]{1,62}[a-z0-9]$", var.configuration.custom_subdomain_name))
    error_message = "Supply explicit 3-64 character account and custom subdomain names; use lowercase alphanumeric/hyphens for the globally unique subdomain."
  }
  validation {
    condition     = length(var.configuration.projects) > 0 && alltrue([for name, p in var.configuration.projects : can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}[a-zA-Z0-9]$", name))])
    error_message = "At least one explicitly named project is required; use 2-64 alphanumeric/hyphen characters."
  }
  validation {
    condition     = alltrue(flatten([for p in values(var.configuration.projects) : [for u in values(p.users) : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", u.principal_id)) && contains(["User", "Group", "ServicePrincipal"], u.principal_type)]]))
    error_message = "Project users require Entra object UUIDs and explicit supported principal types."
  }
  validation {
    condition     = var.configuration.enable_model_deployments || length(var.configuration.deployments) == 0
    error_message = "Model deployment activation must be explicit; remove deployment requests or enable_model_deployments."
  }
  validation {
    condition = alltrue([for m in values(var.configuration.approved_models) :
      alltrue([for s in [m.format, m.name, m.version] : length(trimspace(s)) > 0]) &&
      length(m.permitted_regions) > 0 && length(m.permitted_skus) > 0 &&
      alltrue([for s in m.permitted_skus : contains(["Standard", "DataZoneBatch", "DataZoneStandard", "DataZoneProvisionedManaged", "GlobalBatch", "GlobalProvisionedManaged", "GlobalStandard", "ProvisionedManaged"], s)]) &&
      m.max_capacity > 0 && m.max_capacity == floor(m.max_capacity)
    ])
    error_message = "Approval entries require explicit model format/name/version, regions, supported SKUs, and a positive integer capacity ceiling."
  }
  validation {
    condition = alltrue([for name, d in var.configuration.deployments :
      can(regex("^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,63}$", name)) &&
      d.capacity > 0 && d.capacity == floor(d.capacity) &&
      try(contains(var.configuration.approved_models[d.approval_id].permitted_regions, var.location) &&
        contains(var.configuration.approved_models[d.approval_id].permitted_skus, d.sku_name) &&
      d.capacity <= var.configuration.approved_models[d.approval_id].max_capacity, false)
    ])
    error_message = "Every deployment must reference an approved model for this region/SKU, within its positive integer capacity ceiling, and use a valid deployment name."
  }
  validation {
    condition     = alltrue([for p in values(var.configuration.projects) : (!p.key_vault_secret_read || var.key_vault_id != null) && (!p.storage_blob_read || var.storage_account_id != null)])
    error_message = "Opt-in project data grants require the corresponding existing Key Vault/storage resource ID."
  }
}
variable "resource_group_name" { type = string }
variable "subscription_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "Supply the subscription UUID for resource-scoped role definitions."
  }
}
variable "location" { type = string }
variable "tags" { type = map(string) }
variable "approved_locations" {
  type = set(string)
  validation {
    condition     = length(var.approved_locations) > 0 && contains(var.approved_locations, var.location)
    error_message = "The account/project region must be explicitly approved."
  }
}
variable "key_vault_id" {
  type    = string
  default = null
  validation {
    condition     = var.key_vault_id == null ? true : can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.KeyVault/vaults/[^/]+$", var.key_vault_id))
    error_message = "Key Vault scope must be a vault resource ID."
  }
}
variable "storage_account_id" {
  type    = string
  default = null
  validation {
    condition     = var.storage_account_id == null ? true : can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Storage/storageAccounts/[^/]+$", var.storage_account_id))
    error_message = "Storage scope must be a storage account resource ID."
  }
}
variable "openai_inference_principals" {
  description = "Stable caller labels to existing managed identity/service principal object IDs. Opt-in OpenAI inference, not model management. IDs may be unknown until apply."
  type        = map(string)
  default     = {}
  validation {
    condition     = alltrue([for id in values(var.openai_inference_principals) : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", id))])
    error_message = "OpenAI inference callers must be existing Entra principal UUIDs."
  }
}
