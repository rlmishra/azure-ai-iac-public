variable "name_prefix" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,30}$", var.name_prefix))
    error_message = "Use a 3-31 character lowercase deployment prefix."
  }
}
variable "organization_id" {
  type = string
  validation {
    condition     = length(trimspace(var.organization_id)) > 0 && var.organization_id != "UNCONFIGURED"
    error_message = "Supply the explicit approved organization_id."
  }
}
variable "environment_id" {
  type = string
  validation {
    condition     = length(trimspace(var.environment_id)) > 0 && var.environment_id != "UNCONFIGURED"
    error_message = "Supply the explicit approved environment_id."
  }
}
variable "platform" {
  type = object({
    hosting_model                         = optional(string)
    backend_rbac_confirmed                = optional(bool, false)
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
  nullable = false
  validation {
    condition     = var.platform.hosting_model == "azure_vm" && var.platform.backend_rbac_confirmed
    error_message = "IMDS backend authentication requires explicit hosting_model=azure_vm and reviewed account-scoped OpenAI User access for the VM-attached UAMI. AKS, App Service and hosted gateways need a different reviewed authentication implementation."
  }
  validation {
    condition     = can(regex("^4[.]13[.][0-9]+$", var.platform.server_version)) && var.platform.server_version == var.platform.gateway_version && length(trimspace(var.platform.edition)) > 0
    error_message = "This reference implementation requires explicitly inventoried matching APIM server/gateway 4.13.x versions and edition."
  }
  validation {
    condition     = alltrue([var.platform.automation_api_confirmed, var.platform.license_entitlement_confirmed, var.platform.policy_schema_compatibility_confirmed, var.platform.azure_vm_managed_identity_confirmed, var.platform.private_dns_tls_egress_confirmed, var.platform.distributed_counter_store_confirmed])
    error_message = "Activation requires reviewed Automation API, licensing/plugin schemas, Azure VM identity topology, private DNS/TLS/egress and distributed counters; no installed compatibility is assumed."
  }
  validation {
    condition     = alltrue([for id in ["jwt", "http-proxy", "policy-interrupt", "rate-limit", "quota", "shared-policy-group-policy", "policy-http-callout", "transform-headers", "transform-queryparams"] : try(can(regex("^[0-9]+[.][0-9]+[.][0-9]+([+-].*)?$", var.platform.plugin_versions[id])), false)])
    error_message = "Supply exact reviewed plugin versions for every required policy/HTTP connector and shared-policy invocation."
  }
  validation {
    condition     = try(startswith(var.platform.plugin_versions["jwt"], "8.") && startswith(var.platform.plugin_versions["policy-http-callout"], "6."), false)
    error_message = "The documented 4.13 reference requires JWT 8.x and HTTP Callout 6.x families; exact installed schema compatibility still needs review."
  }
}
variable "consumer_tenant_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.consumer_tenant_id))
    error_message = "Use one explicit Entra tenant UUID; common/multitenant issuers are unsupported."
  }
}
variable "consumer_audience" {
  type = string
  validation {
    condition     = can(regex("^(api://)?[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.consumer_audience))
    error_message = "Use the explicitly approved Entra API audience UUID or api://UUID contract."
  }
}
variable "required_app_role" {
  type = string
  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9._-]{0,63}$", var.required_app_role))
    error_message = "An explicit app role is required; only alphanumeric/dot/underscore/hyphen role names are supported."
  }
}
variable "imds_identity_client_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.imds_identity_client_id))
    error_message = "Select the user-assigned managed identity client UUID attached to the gateway's Azure VM."
  }
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
  validation {
    condition = alltrue([for b in values(var.approved_backends) :
      length(trimspace(b.approval_reference)) > 0 && b.contract == "azure_openai_chat_completions" &&
      can(regex("^https://[a-z0-9][a-z0-9-]*[.]openai[.]azure[.]com/$", b.openai_endpoint)) &&
      can(regex("^[A-Za-z0-9][A-Za-z0-9_.-]{0,63}$", b.deployment_name)) &&
      can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}(-preview)?$", b.api_version)) &&
      can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.CognitiveServices/accounts/[^/]+/deployments/[^/]+$", b.phase2_deployment_id)) &&
      endswith(b.phase2_deployment_id, "/deployments/${b.deployment_name}")
    ])
    error_message = "Backends require explicit approval and Phase 2 deployment IDs, public-Azure HTTPS OpenAI hostnames, explicit deployment/API version and the supported classic chat/completions contract. Project/unified/MCP endpoints are unsupported."
  }
}
variable "apis" {
  type = map(object({
    backend             = string
    context_path        = string
    requests_per_minute = number
    requests_per_day    = number
  }))
  validation {
    condition = alltrue([for name, a in var.apis :
      can(regex("^[a-z][a-z0-9-]{1,30}$", name)) && contains(keys(var.approved_backends), a.backend) &&
      can(regex("^/[a-z0-9-]+(/[a-z0-9-]+)*/$", a.context_path)) &&
      a.requests_per_minute > 0 && floor(a.requests_per_minute) == a.requests_per_minute &&
      a.requests_per_day > 0 && floor(a.requests_per_day) == a.requests_per_day
    ]) && length(distinct([for a in values(var.apis) : a.context_path])) == length(var.apis)
    error_message = "APIs require approved backends, distinct explicit context paths and positive integer request limits/quotas."
  }
  validation {
    condition     = alltrue(flatten([for k, a in var.apis : [for other, b in var.apis : k == other || !startswith(a.context_path, b.context_path)]]))
    error_message = "API context paths must not overlap by prefix."
  }
}
variable "applications" {
  type    = map(object({ name = string, client_id = string }))
  default = {}
  validation {
    condition     = alltrue([for k, a in var.applications : can(regex("^[a-z][a-z0-9-]{1,30}$", k)) && length(trimspace(a.name)) > 0 && can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", a.client_id))]) && length(distinct([for a in values(var.applications) : lower(a.client_id)])) == length(var.applications)
    error_message = "Applications require unique existing Entra client UUIDs and nonempty names. No OAuth DCR, secrets or API keys are accepted."
  }
}
variable "subscriptions" {
  type    = map(object({ api = string, application = string, ending_at = string }))
  default = {}
  validation {
    condition     = alltrue([for k, s in var.subscriptions : contains(keys(var.apis), s.api) && contains(keys(var.applications), s.application) && try(timecmp(s.ending_at, plantimestamp()) > 0, false)]) && length(distinct([for s in values(var.subscriptions) : "${s.api}/${s.application}"])) == length(var.subscriptions)
    error_message = "Subscriptions must reference known APIs/applications, have explicit future RFC3339 expiry and not duplicate an API/application pair."
  }
  validation {
    condition     = var.publish_apis || length(var.subscriptions) == 0
    error_message = "Subscriptions require explicitly published plans; draft defaults create no subscriptions."
  }
}
variable "publish_apis" {
  type    = bool
  default = false
}
variable "enable_tracing" {
  type    = bool
  default = false
  validation {
    condition     = !var.enable_tracing || (var.platform.tracing_exporter_redaction_confirmed && var.enable_analytics)
    error_message = "Tracing requires confirmed exporter setup and redaction review. Payload/log export remains disabled."
  }
}

variable "enable_analytics" {
  type    = bool
  default = false
  validation {
    condition     = !var.enable_analytics || var.platform.analytics_privacy_confirmed
    error_message = "Analytics require explicit metadata/privacy review; request/response content and header logging remain disabled."
  }
}
