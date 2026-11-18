mock_provider "apim" {}
run "disabled_default" {
  command = plan
  assert {
    condition     = output.gateway == null
    error_message = "Disabled defaults must create no APIM stack."
  }
}
run "enabled_private_draft" {
  command = plan
  variables {
    organization_id    = "mock-org"
    environment_id     = "mock-env"
    platform           = { "hosting_model" : "azure_vm", "backend_rbac_confirmed" : true, "server_version" : "4.13.0", "gateway_version" : "4.13.0", "edition" : "MOCK INVENTORY ONLY - NOT A LICENSE CLAIM", "plugin_versions" : { "jwt" : "8.0.0", "http-proxy" : "1.0.0", "policy-interrupt" : "1.0.0", "rate-limit" : "1.0.0", "quota" : "1.0.0", "shared-policy-group-policy" : "1.0.0", "policy-http-callout" : "6.0.0", "transform-headers" : "1.0.0", "transform-queryparams" : "1.0.0" }, "automation_api_confirmed" : true, "license_entitlement_confirmed" : true, "policy_schema_compatibility_confirmed" : true, "azure_vm_managed_identity_confirmed" : true, "private_dns_tls_egress_confirmed" : true, "distributed_counter_store_confirmed" : true }
    approved_backends  = { "approved" : { "approval_reference" : "MOCK-APPROVAL-ONLY", "contract" : "azure_openai_chat_completions", "openai_endpoint" : "https://sample-foundry.openai.azure.com/", "deployment_name" : "chat", "api_version" : "2024-10-21", "phase2_deployment_id" : "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-test/providers/Microsoft.CognitiveServices/accounts/sample-foundry/deployments/chat" } }
    apis               = { "chat" : { "backend" : "approved", "context_path" : "/ai/dev/chat/", "requests_per_minute" : 60, "requests_per_day" : 1000 } }
    applications       = { "client" : { "name" : "Existing Entra application", "client_id" : "55555555-5555-5555-5555-555555555555" } }
    deployment_enabled = true
    management_url     = "https://management.example.org/automation"
    consumer           = { "tenant_id" : "22222222-2222-2222-2222-222222222222", "audience" : "33333333-3333-3333-3333-333333333333", "required_app_role" : "AI.Invoke", "backend_imds_identity_client_id" : "44444444-4444-4444-4444-444444444444" }
  }
  assert {
    condition     = output.gateway.apis["chat"].state == "STOPPED" && output.gateway.apis["chat"].visibility == "PRIVATE" && length(output.gateway.subscriptions) == 0
    error_message = "Root activation must retain private draft defaults and no subscriptions."
  }
}
run "reject_missing_activation_inputs" {
  command = plan
  variables { deployment_enabled = true }
  expect_failures = [var.deployment_enabled]
}
