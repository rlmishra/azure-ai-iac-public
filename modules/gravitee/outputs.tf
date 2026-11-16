output "apis" { value = { for k, a in apim_apiv4.this : k => { id = a.id, hrid = a.hrid, state = a.state, visibility = a.visibility, context_path = var.apis[k].context_path } } }
output "applications" { value = { for k, a in apim_application.this : k => a.hrid } }
output "subscriptions" { value = { for k, s in apim_subscription.this : k => s.hrid } }
output "shared_policy_groups" { value = { for k, s in apim_shared_policy_group.limits : k => s.hrid } }
output "policy_contract" {
  description = "Non-secret generated configuration for offline schema checking. Runtime OAuth tokens are not Terraform values."
  value = {
    jwt       = local.jwt_configuration
    limits    = local.limit_steps
    requests  = { for k, a in apim_apiv4.this : k => a.flows[0].request }
    responses = { for k, a in apim_apiv4.this : k => a.flows[0].response }
  }
}
