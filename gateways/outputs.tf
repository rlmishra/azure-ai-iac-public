output "gateway" {
  value = var.deployment_enabled ? { apis = module.gravitee[0].apis, applications = module.gravitee[0].applications, subscriptions = module.gravitee[0].subscriptions, shared_policy_groups = module.gravitee[0].shared_policy_groups } : null
}
