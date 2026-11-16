mock_provider "azurerm" {
  mock_resource "azurerm_cognitive_account" {
    override_during = plan
    defaults = {
      id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-test/providers/Microsoft.CognitiveServices/accounts/foundry-test"
    }
  }
  mock_resource "azurerm_cognitive_account_project" {
    override_during = plan
    defaults = {
      id       = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-test/providers/Microsoft.CognitiveServices/accounts/foundry-test/projects/research"
      identity = { principal_id = "33333333-3333-3333-3333-333333333333", tenant_id = "22222222-2222-2222-2222-222222222222" }
    }
  }
}
variables {
  subscription_id     = "11111111-1111-1111-1111-111111111111"
  resource_group_name = "rg-test"
  location            = "eastus2"
  approved_locations  = ["eastus2"]
  tags                = { environment = "test" }
  configuration = {
    account_name          = "foundry-test"
    custom_subdomain_name = "foundry-test"
    projects              = { research = {} }
  }
}
run "isolated_account_defaults" {
  command = plan
  module { source = "./modules/foundry" }

  assert {
    condition     = azurerm_cognitive_account.this.network_acls[0].default_action == "Deny" && azurerm_cognitive_account.this.network_acls[0].bypass == "None" && azurerm_cognitive_account.this.identity[0].type == "SystemAssigned"
    error_message = "Account must deny ingress and bypass, with managed identity."
  }
  assert {
    condition     = length(azurerm_cognitive_deployment.this) == 0 && length(azurerm_role_assignment.project_account) == 0 && length(azurerm_role_assignment.project_user) == 0
    error_message = "No automatic model deployments or implicit account/project role grants."
  }
}
run "least_privilege_roles" {
  command = plan
  module { source = "./modules/foundry" }

  variables {
    configuration = {
      account_name          = "foundry-test"
      custom_subdomain_name = "foundry-test"
      projects              = { research = { grant_account_access = true, users = { analyst = { principal_id = "44444444-4444-4444-4444-444444444444", principal_type = "User" } } } }
    }
    openai_inference_principals = { app = "55555555-5555-5555-5555-555555555555" }
  }
  assert {
    condition     = azurerm_role_assignment.openai_inference["app"].scope == azurerm_cognitive_account.this.id && endswith(azurerm_role_assignment.openai_inference["app"].role_definition_id, "/5e0bd9bd-7b93-4f28-af87-19fc36ad61bd")
    error_message = "Application inference must use the stable OpenAI User role at the account scope."
  }
  assert {
    condition     = azurerm_role_assignment.project_user["research/analyst"].scope == azurerm_cognitive_account_project.this["research"].id && endswith(azurerm_role_assignment.project_user["research/analyst"].role_definition_id, "/53ca6127-db72-4b80-b1b0-d745d6d5456d") && azurerm_role_assignment.project_user["research/analyst"].principal_type == "User"
    error_message = "Human project users must be project-scoped with the stable Foundry User role."
  }
}
run "explicit_approved_model" {
  command = plan
  module { source = "./modules/foundry" }
  variables { configuration = {
    account_name             = "foundry-test"
    custom_subdomain_name    = "foundry-test"
    projects                 = { research = {} }
    enable_model_deployments = true
    approved_models = { approved = {
      format            = "OpenAI"
      name              = "gpt-4o"
      version           = "2024-11-20"
      permitted_regions = ["eastus2"]
      permitted_skus    = ["Standard"]
      max_capacity      = 10
    } }
    deployments = { chat = { approval_id = "approved", sku_name = "Standard", capacity = 1 } }
  } }
  assert {
    condition     = azurerm_cognitive_deployment.this["chat"].model[0].version == "2024-11-20" && azurerm_cognitive_deployment.this["chat"].sku[0].capacity == 1 && azurerm_cognitive_deployment.this["chat"].version_upgrade_option == "NoAutoUpgrade"
    error_message = "Model version/capacity must remain explicitly approved and automatic upgrades disabled."
  }
}
run "reject_missing_approval" {
  command = plan
  module { source = "./modules/foundry" }
  variables { configuration = {
    account_name             = "foundry-test"
    custom_subdomain_name    = "foundry-test"
    projects                 = { research = {} }
    enable_model_deployments = true
    approved_models = { approved = {
      format            = "OpenAI"
      name              = "gpt-4o"
      version           = "2024-11-20"
      permitted_regions = ["eastus2"]
      permitted_skus    = ["Standard"]
      max_capacity      = 10
    } }
    deployments = { chat = { approval_id = "unknown", sku_name = "Standard", capacity = 1 } }
  } }
  expect_failures = [var.configuration]
}
run "reject_model_region" {
  command = plan
  module { source = "./modules/foundry" }
  variables { configuration = {
    account_name             = "foundry-test"
    custom_subdomain_name    = "foundry-test"
    projects                 = { research = {} }
    enable_model_deployments = true
    approved_models = { approved = {
      format            = "OpenAI"
      name              = "gpt-4o"
      version           = "2024-11-20"
      permitted_regions = ["westus3"]
      permitted_skus    = ["Standard"]
      max_capacity      = 10
    } }
    deployments = { chat = { approval_id = "approved", sku_name = "Standard", capacity = 1 } }
  } }
  expect_failures = [var.configuration]
}
run "reject_model_sku" {
  command = plan
  module { source = "./modules/foundry" }
  variables { configuration = {
    account_name             = "foundry-test"
    custom_subdomain_name    = "foundry-test"
    projects                 = { research = {} }
    enable_model_deployments = true
    approved_models = { approved = {
      format            = "OpenAI"
      name              = "gpt-4o"
      version           = "2024-11-20"
      permitted_regions = ["eastus2"]
      permitted_skus    = ["Standard"]
      max_capacity      = 10
    } }
    deployments = { chat = { approval_id = "approved", sku_name = "GlobalStandard", capacity = 1 } }
  } }
  expect_failures = [var.configuration]
}
run "reject_capacity_ceiling" {
  command = plan
  module { source = "./modules/foundry" }
  variables { configuration = {
    account_name             = "foundry-test"
    custom_subdomain_name    = "foundry-test"
    projects                 = { research = {} }
    enable_model_deployments = true
    approved_models = { approved = {
      format            = "OpenAI"
      name              = "gpt-4o"
      version           = "2024-11-20"
      permitted_regions = ["eastus2"]
      permitted_skus    = ["Standard"]
      max_capacity      = 10
    } }
    deployments = { chat = { approval_id = "approved", sku_name = "Standard", capacity = 11 } }
  } }
  expect_failures = [var.configuration]
}
run "reject_fractional_capacity" {
  command = plan
  module { source = "./modules/foundry" }
  variables { configuration = {
    account_name             = "foundry-test"
    custom_subdomain_name    = "foundry-test"
    projects                 = { research = {} }
    enable_model_deployments = true
    approved_models = { approved = {
      format            = "OpenAI"
      name              = "gpt-4o"
      version           = "2024-11-20"
      permitted_regions = ["eastus2"]
      permitted_skus    = ["Standard"]
      max_capacity      = 10
    } }
    deployments = { chat = { approval_id = "approved", sku_name = "Standard", capacity = 1.5 } }
  } }
  expect_failures = [var.configuration]
}
run "reject_implicit_version" {
  command = plan
  module { source = "./modules/foundry" }
  variables { configuration = {
    account_name             = "foundry-test"
    custom_subdomain_name    = "foundry-test"
    projects                 = { research = {} }
    enable_model_deployments = true
    approved_models = { approved = {
      format            = "OpenAI"
      name              = "gpt-4o"
      version           = ""
      permitted_regions = ["eastus2"]
      permitted_skus    = ["Standard"]
      max_capacity      = 10
    } }
    deployments = { chat = { approval_id = "approved", sku_name = "Standard", capacity = 1 } }
  } }
  expect_failures = [var.configuration]
}
run "reject_unactivated_model" {
  command = plan
  module { source = "./modules/foundry" }
  variables { configuration = {
    account_name             = "foundry-test"
    custom_subdomain_name    = "foundry-test"
    projects                 = { research = {} }
    enable_model_deployments = false
    approved_models = { approved = {
      format            = "OpenAI"
      name              = "gpt-4o"
      version           = "2024-11-20"
      permitted_regions = ["eastus2"]
      permitted_skus    = ["Standard"]
      max_capacity      = 10
    } }
    deployments = { chat = { approval_id = "approved", sku_name = "Standard", capacity = 1 } }
  } }
  expect_failures = [var.configuration]
}
run "reject_no_projects" {
  command = plan
  module { source = "./modules/foundry" }
  variables { configuration = {
    account_name             = "foundry-test"
    custom_subdomain_name    = "foundry-test"
    projects                 = {}
    enable_model_deployments = true
    approved_models = { approved = {
      format            = "OpenAI"
      name              = "gpt-4o"
      version           = "2024-11-20"
      permitted_regions = ["eastus2"]
      permitted_skus    = ["Standard"]
      max_capacity      = 10
    } }
    deployments = { chat = { approval_id = "approved", sku_name = "Standard", capacity = 1 } }
  } }
  expect_failures = [var.configuration]
}
run "reject_missing_data_scope" {
  command = plan
  module { source = "./modules/foundry" }
  variables { configuration = {
    account_name             = "foundry-test"
    custom_subdomain_name    = "foundry-test"
    projects                 = { research = { key_vault_secret_read = true } }
    enable_model_deployments = true
    approved_models = { approved = {
      format            = "OpenAI"
      name              = "gpt-4o"
      version           = "2024-11-20"
      permitted_regions = ["eastus2"]
      permitted_skus    = ["Standard"]
      max_capacity      = 10
    } }
    deployments = { chat = { approval_id = "approved", sku_name = "Standard", capacity = 1 } }
  } }
  expect_failures = [var.configuration]
}
run "reject_invalid_principal" {
  command = plan
  module { source = "./modules/foundry" }
  variables { configuration = {
    account_name             = "foundry-test"
    custom_subdomain_name    = "foundry-test"
    projects                 = { research = { users = { app = { principal_id = "invalid" } } } }
    enable_model_deployments = true
    approved_models = { approved = {
      format            = "OpenAI"
      name              = "gpt-4o"
      version           = "2024-11-20"
      permitted_regions = ["eastus2"]
      permitted_skus    = ["Standard"]
      max_capacity      = 10
    } }
    deployments = { chat = { approval_id = "approved", sku_name = "Standard", capacity = 1 } }
  } }
  expect_failures = [var.configuration]
}
run "reject_invalid_account_name" {
  command = plan
  module { source = "./modules/foundry" }
  variables { configuration = {
    account_name             = "invalid account"
    custom_subdomain_name    = "foundry-test"
    projects                 = { research = {} }
    enable_model_deployments = true
    approved_models = { approved = {
      format            = "OpenAI"
      name              = "gpt-4o"
      version           = "2024-11-20"
      permitted_regions = ["eastus2"]
      permitted_skus    = ["Standard"]
      max_capacity      = 10
    } }
    deployments = { chat = { approval_id = "approved", sku_name = "Standard", capacity = 1 } }
  } }
  expect_failures = [var.configuration]
}
run "reject_account_region" {
  command = plan
  module { source = "./modules/foundry" }
  variables { approved_locations = ["westus3"] }
  expect_failures = [var.approved_locations]
}
