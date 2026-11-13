mock_provider "azurerm" {}
variables {
  subscription_id      = "11111111-1111-1111-1111-111111111111"
  tenant_id            = "22222222-2222-2222-2222-222222222222"
  name                 = "aicore"
  environment          = "prod"
  location             = "eastus2"
  approved_locations   = ["eastus2"]
  tags                 = { owner = "platform", cost_center = "42", data_classification = "confidential", application = "ai" }
  key_vault_name       = "kv-aicore-dev-test"
  storage_account_name = "staicoredevtest"
  address_space        = ["10.40.0.0/16"]
  workload_prefixes    = ["10.40.1.0/24"]
  endpoint_prefixes    = ["10.40.2.0/24"]
}
run "private_foundation" {
  command = plan
  assert {
    condition     = !output.security_posture.vault_public_access && output.security_posture.vault_rbac && output.security_posture.vault_purge_protection
    error_message = "Key Vault must be private, RBAC-authorized and purge protected."
  }
  assert {
    condition     = output.security_posture.storage_public_access == "Disabled" && !output.security_posture.storage_shared_keys && output.security_posture.storage_infrastructure_encryption
    error_message = "Storage must be private, keyless and doubly encrypted."
  }
  assert {
    condition     = output.monitoring_posture.ingestion == "Disabled" && output.monitoring_posture.query == "Disabled" && !output.monitoring_posture.local_auth && output.monitoring_posture.scope_ingestion == "PrivateOnly" && output.monitoring_posture.scope_query == "PrivateOnly"
    error_message = "Monitoring must require private access and Entra authentication."
  }
  assert {
    condition     = length(output.private_endpoint_ids) == 3 && length(module.identity.role_assignment_ids) == 0
    error_message = "Three private endpoints and no automatic data grants are required."
  }
  assert {
    condition     = output.tags.environment == "prod" && output.tags.managed_by == "terraform" && !module.networking.default_outbound_access_enabled
    error_message = "Governance tags and explicit outbound access are required."
  }
}
run "approved_data_grants" {
  command = plan
  variables { grant_workload_data_access = true }
  assert {
    condition     = length(module.identity.role_assignment_ids) == 3
    error_message = "Opt-in should grant exactly secrets read, blobs read and telemetry publishing."
  }
}
run "reject_unapproved_region" {
  command = plan
  variables { location = "westus3" }
  expect_failures = [var.approved_locations]
}
run "reject_missing_tags" {
  command = plan
  variables { tags = { owner = "platform" } }
  expect_failures = [var.tags]
}
run "reject_invalid_storage_name" {
  command = plan
  variables { storage_account_name = "INVALID-storage" }
  expect_failures = [var.storage_account_name]
}
run "reject_small_endpoint_subnet" {
  command = plan
  variables { endpoint_prefixes = ["10.40.2.0/29"] }
  expect_failures = [var.endpoint_prefixes]
}

run "reject_overlapping_subnets" {
  command = plan
  variables { endpoint_prefixes = ["10.40.1.128/25"] }
  expect_failures = [var.endpoint_prefixes]
}
run "reject_subnet_outside_vnet" {
  command = plan
  variables { workload_prefixes = ["10.99.1.0/24"] }
  expect_failures = [var.workload_prefixes]
}
