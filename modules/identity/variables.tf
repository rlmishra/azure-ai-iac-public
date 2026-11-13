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
variable "assignments" {
  description = "Explicit resource-scoped grants to the workload identity or supplied existing Entra object IDs."
  type        = map(object({ scope = string, role_definition_name = string, principal_id = optional(string), principal_type = optional(string, "ServicePrincipal") }))
  default     = {}
  validation {
    condition     = alltrue([for a in values(var.assignments) : contains(["Key Vault Secrets User", "Storage Blob Data Reader", "Storage Blob Data Contributor", "Monitoring Metrics Publisher", "Monitoring Reader", "Log Analytics Reader"], a.role_definition_name)])
    error_message = "Only approved data or monitoring roles are allowed; extend the reviewed allowlist for additional roles."
  }
  validation {
    condition     = alltrue([for a in values(var.assignments) : can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/", a.scope))])
    error_message = "Assignments must target a resource, not a subscription or resource group."
  }
}
