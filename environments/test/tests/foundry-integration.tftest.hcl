mock_provider "azurerm" {}
variables {
  subscription_id      = "11111111-1111-1111-1111-111111111111"
  tenant_id            = "22222222-2222-2222-2222-222222222222"
  name                 = "aicore"
  environment          = "test"
  location             = "eastus2"
  approved_locations   = ["eastus2"]
  tags                 = { owner = "platform", cost_center = "42", data_classification = "confidential", application = "ai" }
  key_vault_name       = "kv-aicore-dev-test"
  storage_account_name = "staicoredevtest"
  address_space        = ["10.40.0.0/16"]
  workload_prefixes    = ["10.40.1.0/24"]
  endpoint_prefixes    = ["10.40.2.0/24"]
}

run "foundry_private_without_models" {
  command = plan
  variables {
    foundry = {
      account_name          = "foundry-example-dev"
      custom_subdomain_name = "foundry-example-dev"
      projects              = { research = {} }
    }
  }
  assert {
    condition     = output.foundry.posture.kind == "AIServices" && output.foundry.posture.project_management && !output.foundry.posture.public_network_access && !output.foundry.posture.local_auth && output.foundry.posture.outbound_restricted
    error_message = "Foundry must use private, keyless AIServices account/project architecture."
  }
  assert {
    condition     = output.foundry.posture.deployment_count == 0 && output.foundry.posture.role_assignment_count == 0 && length(output.foundry.projects) == 1
    error_message = "Projects must not silently create models or RBAC grants."
  }
  assert {
    condition     = length(output.private_endpoint_ids) == 4 && length(module.networking.dns_zone_ids) == 9
    error_message = "Enablement must add one account endpoint and exactly three private zones."
  }
  assert {
    condition     = output.security_posture.storage_public_access == "Disabled" && !output.security_posture.vault_public_access
    error_message = "Existing storage and vault isolation must remain enabled."
  }
}
run "approved_workload_inference" {
  command = plan
  variables {
    foundry = {
      account_name          = "foundry-example-dev"
      custom_subdomain_name = "foundry-example-dev"
      projects              = { research = {} }
    }
    foundry_grant_workload_openai_access = true
  }
  assert {
    condition     = output.foundry.posture.role_assignment_count == 1 && length(module.identity.role_assignment_ids) == 0
    error_message = "Only the explicit OpenAI inference grant may be added; Phase 1 role defaults must stay unchanged."
  }
}
run "approved_project_runtime_grants" {
  command = plan
  variables {
    foundry = {
      account_name          = "foundry-example-dev"
      custom_subdomain_name = "foundry-example-dev"
      projects              = { research = { grant_account_access = true, key_vault_secret_read = true, storage_blob_read = true } }
    }
  }
  assert {
    condition     = output.foundry.posture.role_assignment_count == 3
    error_message = "Only the explicitly selected account, vault-read and blob-read grants may be created."
  }
}
run "foundry_disabled_preserves_foundation" {
  command = plan
  assert {
    condition     = output.foundry == null && length(output.private_endpoint_ids) == 3 && length(module.networking.dns_zone_ids) == 6
    error_message = "Default configuration must retain Phase 1 topology without Foundry resources."
  }
}
run "reject_inference_without_foundry" {
  command = plan
  variables { foundry_grant_workload_openai_access = true }
  expect_failures = [var.foundry_grant_workload_openai_access]
}

run "root_approved_model_deployment" {
  command = plan
  variables {
    # Test-only catalog entry; not a claim of current region availability.
    foundry = {
      account_name             = "foundry-example-dev"
      custom_subdomain_name    = "foundry-example-dev"
      projects                 = { research = {} }
      enable_model_deployments = true
      approved_models = {
        test_fixture = { format = "OpenAI", name = "gpt-4o", version = "2024-11-20", permitted_regions = ["eastus2"], permitted_skus = ["Standard"], max_capacity = 10 }
      }
      deployments = { chat = { approval_id = "test_fixture", sku_name = "Standard", capacity = 1 } }
    }
  }
  assert {
    condition     = output.foundry.posture.deployment_count == 1 && output.foundry.deployments["chat"].model.version == "2024-11-20" && output.foundry.deployments["chat"].version_upgrade_option == "NoAutoUpgrade"
    error_message = "Root integration must preserve the explicit model approval and version pin."
  }
}
