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
variable "tenant_id" {
  type = string
}
variable "key_vault_name" {
  type = string
}
variable "storage_account_name" {
  type = string
}
variable "storage_replication_type" {
  type    = string
  default = "ZRS"
  validation {
    condition     = contains(["ZRS", "GZRS", "RAGZRS"], var.storage_replication_type)
    error_message = "Choose a zone-redundant replication mode supported in the approved region."
  }
}
variable "policy_assignments" {
  description = "Existing deny/audit policy or initiative IDs; remediation identities are intentionally excluded."
  type        = map(object({ policy_definition_id = string, parameters = optional(string, "{}"), description = optional(string, "Enterprise landing-zone guardrail") }))
  default     = {}
  validation {
    condition     = alltrue([for k, v in var.policy_assignments : length(k) <= 24 && can(jsondecode(v.parameters))])
    error_message = "Policy assignment names must be <=24 characters and parameters must be JSON."
  }
}
variable "resource_group_id" {
  type = string
}
