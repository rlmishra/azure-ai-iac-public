provider "apim" {
  server_url      = var.management_url
  organization_id = var.organization_id
  environment_id  = var.environment_id
  # Management credentials ONLY via APIM_SA_TOKEN (or approved APIM_CLOUD_TOKEN).
  # Never use provider secret literals, API-key plans, or Terraform secret variables.
}
