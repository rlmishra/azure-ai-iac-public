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
variable "retention_in_days" {
  type    = number
  default = 90
  validation {
    condition     = var.retention_in_days >= 90 && var.retention_in_days <= 730
    error_message = "Retention must be 90 to 730 days."
  }
}
variable "diagnostic_targets" {
  description = "Explicit categories checked against each target's Azure diagnostic settings API before deployment."
  type        = map(object({ resource_id = string, log_categories = optional(set(string), []), log_category_groups = optional(set(string), []), metric_categories = optional(set(string), []) }))
  default     = {}
}
