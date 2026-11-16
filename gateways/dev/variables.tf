variable "environment" {
  type    = string
  default = "dev"
  validation {
    condition     = var.environment == "dev"
    error_message = "Use the environment owned by this state root."
  }
}
variable "deployment_enabled" {
  type    = bool
  default = false
  validation {
    condition     = !var.deployment_enabled || (var.platform != null && var.consumer != null && length(var.apis) > 0 && !strcontains(var.management_url, ".invalid"))
    error_message = "Activation requires actual reviewed platform, consumer, API and management settings."
  }
}
variable "management_url" {
  type    = string
  default = "https://management.invalid/automation"
  validation {
    condition     = can(regex("^https://[A-Za-z0-9.-]+(:[0-9]+)?/.*automation/?$", var.management_url))
    error_message = "Supply an HTTPS Automation API URL without embedded credentials or query parameters."
  }
}
variable "organization_id" {
  type    = string
  default = "UNCONFIGURED"
}
variable "environment_id" {
  type    = string
  default = "UNCONFIGURED"
  validation {
    condition     = !var.deployment_enabled || (var.environment_id != "UNCONFIGURED" && var.organization_id != "UNCONFIGURED" && length(trimspace(var.environment_id)) > 0 && length(trimspace(var.organization_id)) > 0)
    error_message = "Explicit organization/environment IDs are required before activation."
  }
}
variable "name" {
  type    = string
  default = "enterprise-ai"
}
variable "platform" {
  type = object({
    server_version                        = string
    gateway_version                       = string
    edition                               = string
    plugin_versions                       = map(string)
    automation_api_confirmed              = optional(bool, false)
    license_entitlement_confirmed         = optional(bool, false)
    policy_schema_compatibility_confirmed = optional(bool, false)
    azure_vm_managed_identity_confirmed   = optional(bool, false)
    private_dns_tls_egress_confirmed      = optional(bool, false)
    distributed_counter_store_confirmed   = optional(bool, false)
    analytics_privacy_confirmed           = optional(bool, false)
    tracing_exporter_redaction_confirmed  = optional(bool, false)
  })
  default = null
}
variable "consumer" {
  type    = object({ tenant_id = string, audience = string, required_app_role = string, backend_imds_identity_client_id = string })
  default = null
}
variable "approved_backends" {
  type = map(object({
    approval_reference   = string
    contract             = string
    openai_endpoint      = string
    deployment_name      = string
    api_version          = string
    phase2_deployment_id = string
  }))
  default = {}
}
variable "apis" {
  type = map(object({
    backend             = string
    context_path        = string
    requests_per_minute = number
    requests_per_day    = number
  }))
  default = {}
}
variable "applications" {
  type    = map(object({ name = string, client_id = string }))
  default = {}
}
variable "subscriptions" {
  type    = map(object({ api = string, application = string, ending_at = string }))
  default = {}
}
variable "publish_apis" {
  type    = bool
  default = false
}
variable "enable_tracing" {
  type    = bool
  default = false
}

variable "enable_analytics" {
  type    = bool
  default = false
}
