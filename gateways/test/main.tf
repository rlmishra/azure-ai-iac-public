module "gravitee" {
  count                   = var.deployment_enabled ? 1 : 0
  source                  = "../../modules/gravitee"
  name_prefix             = "${var.name}-${var.environment}"
  organization_id         = var.organization_id
  environment_id          = var.environment_id
  platform                = var.platform
  consumer_tenant_id      = try(var.consumer.tenant_id, null)
  consumer_audience       = try(var.consumer.audience, null)
  required_app_role       = try(var.consumer.required_app_role, null)
  imds_identity_client_id = try(var.consumer.backend_imds_identity_client_id, null)
  approved_backends       = var.approved_backends
  apis                    = var.apis
  applications            = var.applications
  subscriptions           = var.subscriptions
  publish_apis            = var.publish_apis
  enable_tracing          = var.enable_tracing
  enable_analytics        = var.enable_analytics
}
