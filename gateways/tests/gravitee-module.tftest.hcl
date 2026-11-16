mock_provider "apim" {}
# Synthetic platform/plugin/approval values below are mock fixtures, not installed compatibility claims.
variables {
  name_prefix             = "enterprise-dev"
  organization_id         = "mock-org"
  environment_id          = "mock-env"
  platform                = { "server_version" : "4.13.0", "gateway_version" : "4.13.0", "edition" : "MOCK INVENTORY ONLY - NOT A LICENSE CLAIM", "plugin_versions" : { "jwt" : "8.0.0", "http-proxy" : "1.0.0", "policy-interrupt" : "1.0.0", "rate-limit" : "1.0.0", "quota" : "1.0.0", "shared-policy-group-policy" : "1.0.0", "policy-http-callout" : "6.0.0", "transform-headers" : "1.0.0", "transform-queryparams" : "1.0.0" }, "automation_api_confirmed" : true, "license_entitlement_confirmed" : true, "policy_schema_compatibility_confirmed" : true, "azure_vm_managed_identity_confirmed" : true, "private_dns_tls_egress_confirmed" : true, "distributed_counter_store_confirmed" : true }
  consumer_tenant_id      = "22222222-2222-2222-2222-222222222222"
  consumer_audience       = "33333333-3333-3333-3333-333333333333"
  required_app_role       = "AI.Invoke"
  imds_identity_client_id = "44444444-4444-4444-4444-444444444444"
  approved_backends       = { "approved" : { "approval_reference" : "MOCK-APPROVAL-ONLY", "contract" : "azure_openai_chat_completions", "openai_endpoint" : "https://sample-foundry.openai.azure.com/", "deployment_name" : "chat", "api_version" : "2024-10-21", "phase2_deployment_id" : "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-test/providers/Microsoft.CognitiveServices/accounts/sample-foundry/deployments/chat" } }
  apis                    = { "chat" : { "backend" : "approved", "context_path" : "/ai/dev/chat/", "requests_per_minute" : 60, "requests_per_day" : 1000 } }
  applications            = { "client" : { "name" : "Existing Entra application", "client_id" : "55555555-5555-5555-5555-555555555555" } }
}
run "private_draft_contract" {
  command = plan
  module { source = "../modules/gravitee" }
  assert {
    condition     = apim_apiv4.this["chat"].visibility == "PRIVATE" && apim_apiv4.this["chat"].state == "STOPPED" && apim_apiv4.this["chat"].lifecycle_state == "UNPUBLISHED" && apim_apiv4.this["chat"].plans[0].status == "STAGING"
    error_message = "Draft APIs must not be publicly started/published."
  }
  assert {
    condition     = apim_apiv4.this["chat"].plans[0].security.type == "JWT" && !jsondecode(apim_apiv4.this["chat"].plans[0].security.configuration).propagateAuthHeader && jsondecode(apim_apiv4.this["chat"].plans[0].security.configuration).clientIdClaim == "azp"
    error_message = "Require subscribed Entra JWT applications and prevent consumer token propagation."
  }
  assert {
    condition     = apim_apiv4.this["chat"].flow_execution.match_required && apim_apiv4.this["chat"].flows[0].selectors[0].http.path_operator == "EQUALS" && apim_apiv4.this["chat"].flows[0].selectors[0].http.methods == tolist(["POST"])
    error_message = "Only exact POST route is configured; unmatched flows must fail."
  }
  assert {
    condition     = tolist([for s in apim_apiv4.this["chat"].flows[0].request : s.policy]) == tolist(["policy-interrupt", "shared-policy-group-policy", "transform-headers", "transform-queryparams", "policy-http-callout", "policy-interrupt", "transform-headers"])
    error_message = "Authentication/authorization and limits must precede backend token acquisition."
  }
  assert {
    condition     = !apim_apiv4.this["chat"].analytics.enabled && !apim_apiv4.this["chat"].analytics.logging.content.payload && !apim_apiv4.this["chat"].analytics.logging.content.headers && !apim_apiv4.this["chat"].analytics.otel_logs.enabled && !apim_apiv4.this["chat"].analytics.tracing.enabled
    error_message = "No content/header/OTel payload logging or default tracing."
  }
  assert {
    condition     = jsondecode(apim_shared_policy_group.limits["chat"].steps[0].configuration).errorStrategy == "BLOCK_ON_INTERNAL_ERROR" && !jsondecode(apim_shared_policy_group.limits["chat"].steps[0].configuration).async && jsondecode(apim_shared_policy_group.limits["chat"].steps[1].configuration).quota.limit == 1000
    error_message = "Request limits must be synchronous and fail closed."
  }
  assert {
    condition     = jsondecode(apim_apiv4.this["chat"].flows[0].request[3].configuration).clearAll && jsondecode(apim_apiv4.this["chat"].flows[0].request[3].configuration).addQueryParameters[0].value == "2024-10-21"
    error_message = "Consumer query parameters must not override approved API version."
  }
  assert {
    condition     = startswith(jsondecode(apim_apiv4.this["chat"].flows[0].request[4].configuration).url, "http://169.254.169.254/metadata/identity/oauth2/token?") && jsondecode(apim_apiv4.this["chat"].flows[0].request[4].configuration).exitOnError && !jsondecode(apim_apiv4.this["chat"].flows[0].request[4].configuration).useSystemProxy
    error_message = "IMDS token call must be fixed-host, direct and fail closed."
  }
  assert {
    condition     = length(apim_subscription.this) == 0 && apim_application.this["client"].settings.app.client_id == "55555555-5555-5555-5555-555555555555"
    error_message = "Drafts create no subscriptions or client secrets."
  }
}
run "explicit_publish_and_subscription" {
  command = plan
  module { source = "../modules/gravitee" }
  variables {
    publish_apis  = true
    subscriptions = { "access" : { "api" : "chat", "application" : "client", "ending_at" : "2099-01-01T00:00:00Z" } }
  }
  assert {
    condition     = apim_apiv4.this["chat"].state == "STARTED" && apim_apiv4.this["chat"].visibility == "PRIVATE" && apim_apiv4.this["chat"].plans[0].status == "PUBLISHED" && length(apim_subscription.this) == 1
    error_message = "Only explicit publication may start APIs and create JWT subscriptions."
  }
}
run "explicit_redacted_tracing" {
  command = plan
  module { source = "../modules/gravitee" }
  variables {
    enable_analytics = true
    platform         = { "server_version" : "4.13.0", "gateway_version" : "4.13.0", "edition" : "MOCK INVENTORY ONLY - NOT A LICENSE CLAIM", "plugin_versions" : { "jwt" : "8.0.0", "http-proxy" : "1.0.0", "policy-interrupt" : "1.0.0", "rate-limit" : "1.0.0", "quota" : "1.0.0", "shared-policy-group-policy" : "1.0.0", "policy-http-callout" : "6.0.0", "transform-headers" : "1.0.0", "transform-queryparams" : "1.0.0" }, "automation_api_confirmed" : true, "license_entitlement_confirmed" : true, "policy_schema_compatibility_confirmed" : true, "azure_vm_managed_identity_confirmed" : true, "private_dns_tls_egress_confirmed" : true, "distributed_counter_store_confirmed" : true, "tracing_exporter_redaction_confirmed" : true, "analytics_privacy_confirmed" : true }
    enable_tracing   = true
  }
  assert {
    condition     = apim_apiv4.this["chat"].analytics.tracing.enabled && !apim_apiv4.this["chat"].analytics.tracing.verbose && apim_apiv4.this["chat"].analytics.tracing.redaction.rules[0].masking_strategy.type == "FULL" && !apim_apiv4.this["chat"].analytics.otel_logs.enabled
    error_message = "Tracing must remain nonverbose with full attribute masking and payload logs off."
  }
}
run "reject_http_backend" {
  command = plan
  module { source = "../modules/gravitee" }
  variables {
    approved_backends = { "approved" : { "approval_reference" : "MOCK-APPROVAL-ONLY", "contract" : "azure_openai_chat_completions", "openai_endpoint" : "http://sample-foundry.openai.azure.com/", "deployment_name" : "chat", "api_version" : "2024-10-21", "phase2_deployment_id" : "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-test/providers/Microsoft.CognitiveServices/accounts/sample-foundry/deployments/chat" } }
  }
  expect_failures = [var.approved_backends]
}
run "reject_project_endpoint" {
  command = plan
  module { source = "../modules/gravitee" }
  variables {
    approved_backends = { "approved" : { "approval_reference" : "MOCK-APPROVAL-ONLY", "contract" : "azure_openai_chat_completions", "openai_endpoint" : "https://sample-foundry.services.ai.azure.com/", "deployment_name" : "chat", "api_version" : "2024-10-21", "phase2_deployment_id" : "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-test/providers/Microsoft.CognitiveServices/accounts/sample-foundry/deployments/chat" } }
  }
  expect_failures = [var.approved_backends]
}
run "reject_other_contract" {
  command = plan
  module { source = "../modules/gravitee" }
  variables {
    approved_backends = { "approved" : { "approval_reference" : "MOCK-APPROVAL-ONLY", "contract" : "mcp", "openai_endpoint" : "https://sample-foundry.openai.azure.com/", "deployment_name" : "chat", "api_version" : "2024-10-21", "phase2_deployment_id" : "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-test/providers/Microsoft.CognitiveServices/accounts/sample-foundry/deployments/chat" } }
  }
  expect_failures = [var.approved_backends]
}
run "reject_unapproved_metadata" {
  command = plan
  module { source = "../modules/gravitee" }
  variables {
    approved_backends = { "approved" : { "approval_reference" : "", "contract" : "azure_openai_chat_completions", "openai_endpoint" : "https://sample-foundry.openai.azure.com/", "deployment_name" : "chat", "api_version" : "2024-10-21", "phase2_deployment_id" : "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-test/providers/Microsoft.CognitiveServices/accounts/sample-foundry/deployments/chat" } }
  }
  expect_failures = [var.approved_backends]
}
run "reject_wrong_deployment" {
  command = plan
  module { source = "../modules/gravitee" }
  variables {
    approved_backends = { "approved" : { "approval_reference" : "MOCK-APPROVAL-ONLY", "contract" : "azure_openai_chat_completions", "openai_endpoint" : "https://sample-foundry.openai.azure.com/", "deployment_name" : "other", "api_version" : "2024-10-21", "phase2_deployment_id" : "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-test/providers/Microsoft.CognitiveServices/accounts/sample-foundry/deployments/chat" } }
  }
  expect_failures = [var.approved_backends]
}
run "reject_fractional_request_limit" {
  command = plan
  module { source = "../modules/gravitee" }
  variables {
    apis = { "chat" : { "backend" : "approved", "context_path" : "/ai/dev/chat/", "requests_per_minute" : 1.5, "requests_per_day" : 1000 } }
  }
  expect_failures = [var.apis]
}
run "reject_overlapping_paths" {
  command = plan
  module { source = "../modules/gravitee" }
  variables {
    apis = { "chat" : { "backend" : "approved", "context_path" : "/ai/dev/chat/", "requests_per_minute" : 60, "requests_per_day" : 1000 }, "other" : { "backend" : "approved", "context_path" : "/ai/dev/chat/child/", "requests_per_minute" : 60, "requests_per_day" : 1000 } }
  }
  expect_failures = [var.apis]
}
run "reject_unconfirmed_license" {
  command = plan
  module { source = "../modules/gravitee" }
  variables {
    platform = { "server_version" : "4.13.0", "gateway_version" : "4.13.0", "edition" : "MOCK INVENTORY ONLY - NOT A LICENSE CLAIM", "plugin_versions" : { "jwt" : "8.0.0", "http-proxy" : "1.0.0", "policy-interrupt" : "1.0.0", "rate-limit" : "1.0.0", "quota" : "1.0.0", "shared-policy-group-policy" : "1.0.0", "policy-http-callout" : "6.0.0", "transform-headers" : "1.0.0", "transform-queryparams" : "1.0.0" }, "automation_api_confirmed" : true, "license_entitlement_confirmed" : false, "policy_schema_compatibility_confirmed" : true, "azure_vm_managed_identity_confirmed" : true, "private_dns_tls_egress_confirmed" : true, "distributed_counter_store_confirmed" : true }
  }
  expect_failures = [var.platform]
}
run "reject_runtime_mismatch" {
  command = plan
  module { source = "../modules/gravitee" }
  variables {
    platform = { "server_version" : "4.13.0", "gateway_version" : "4.12.0", "edition" : "MOCK INVENTORY ONLY - NOT A LICENSE CLAIM", "plugin_versions" : { "jwt" : "8.0.0", "http-proxy" : "1.0.0", "policy-interrupt" : "1.0.0", "rate-limit" : "1.0.0", "quota" : "1.0.0", "shared-policy-group-policy" : "1.0.0", "policy-http-callout" : "6.0.0", "transform-headers" : "1.0.0", "transform-queryparams" : "1.0.0" }, "automation_api_confirmed" : true, "license_entitlement_confirmed" : true, "policy_schema_compatibility_confirmed" : true, "azure_vm_managed_identity_confirmed" : true, "private_dns_tls_egress_confirmed" : true, "distributed_counter_store_confirmed" : true }
  }
  expect_failures = [var.platform]
}
run "reject_missing_plugin" {
  command = plan
  module { source = "../modules/gravitee" }
  variables {
    platform = { "server_version" : "4.13.0", "gateway_version" : "4.13.0", "edition" : "MOCK INVENTORY ONLY - NOT A LICENSE CLAIM", "plugin_versions" : { "jwt" : "8.0.0", "http-proxy" : "1.0.0", "policy-interrupt" : "1.0.0", "rate-limit" : "1.0.0", "shared-policy-group-policy" : "1.0.0", "policy-http-callout" : "6.0.0", "transform-headers" : "1.0.0", "transform-queryparams" : "1.0.0" }, "automation_api_confirmed" : true, "license_entitlement_confirmed" : true, "policy_schema_compatibility_confirmed" : true, "azure_vm_managed_identity_confirmed" : true, "private_dns_tls_egress_confirmed" : true, "distributed_counter_store_confirmed" : true }
  }
  expect_failures = [var.platform]
}
run "reject_unconfirmed_identity_topology" {
  command = plan
  module { source = "../modules/gravitee" }
  variables {
    platform = { "server_version" : "4.13.0", "gateway_version" : "4.13.0", "edition" : "MOCK INVENTORY ONLY - NOT A LICENSE CLAIM", "plugin_versions" : { "jwt" : "8.0.0", "http-proxy" : "1.0.0", "policy-interrupt" : "1.0.0", "rate-limit" : "1.0.0", "quota" : "1.0.0", "shared-policy-group-policy" : "1.0.0", "policy-http-callout" : "6.0.0", "transform-headers" : "1.0.0", "transform-queryparams" : "1.0.0" }, "automation_api_confirmed" : true, "license_entitlement_confirmed" : true, "policy_schema_compatibility_confirmed" : true, "azure_vm_managed_identity_confirmed" : false, "private_dns_tls_egress_confirmed" : true, "distributed_counter_store_confirmed" : true }
  }
  expect_failures = [var.platform]
}
run "reject_implicit_tracing" {
  command = plan
  module { source = "../modules/gravitee" }
  variables {
    enable_tracing = true
  }
  expect_failures = [var.enable_tracing]
}
run "reject_common_tenant" {
  command = plan
  module { source = "../modules/gravitee" }
  variables {
    consumer_tenant_id = "common"
  }
  expect_failures = [var.consumer_tenant_id]
}
run "reject_role_expression_injection" {
  command = plan
  module { source = "../modules/gravitee" }
  variables {
    required_app_role = "x' or true"
  }
  expect_failures = [var.required_app_role]
}
run "reject_subscription_in_draft" {
  command = plan
  module { source = "../modules/gravitee" }
  variables {
    subscriptions = { "access" : { "api" : "chat", "application" : "client", "ending_at" : "2099-01-01T00:00:00Z" } }
  }
  expect_failures = [var.subscriptions]
}
run "reject_expired_subscription" {
  command = plan
  module { source = "../modules/gravitee" }
  variables {
    publish_apis  = true
    subscriptions = { "access" : { "api" : "chat", "application" : "client", "ending_at" : "2000-01-01T00:00:00Z" } }
  }
  expect_failures = [var.subscriptions]
}

run "reject_unreviewed_analytics" {
  command = plan
  module { source = "../modules/gravitee" }
  variables { enable_analytics = true }
  expect_failures = [var.enable_analytics]
}
