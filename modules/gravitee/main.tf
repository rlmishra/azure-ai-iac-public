locals {
  issuer = "https://login.microsoftonline.com/${lower(var.consumer_tenant_id)}/v2.0"
  jwt_configuration = jsonencode({
    signature           = "RSA_RS256"
    publicKeyResolver   = "JWKS_URL"
    resolverParameter   = "https://login.microsoftonline.com/${lower(var.consumer_tenant_id)}/discovery/v2.0/keys"
    extractClaims       = true
    propagateAuthHeader = false
    clientIdClaim       = "azp"
    userClaim           = "sub"
    followRedirects     = false
    connectTimeout      = 2000
    requestTimeout      = 2000
  })
  claim_rejection = "{#context.attributes['jwt.claims'] == null or #context.attributes['jwt.claims']['iss'] != '${local.issuer}' or #context.attributes['jwt.claims']['aud'] != '${var.consumer_audience}' or #context.attributes['jwt.claims']['azp'] == null or #context.attributes['jwt.claims']['exp'] == null or #context.attributes['jwt.claims']['roles'] == null or !#context.attributes['jwt.claims']['roles'].contains('${var.required_app_role}')}"
  imds_configuration = jsonencode({
    method          = "GET"
    url             = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fcognitiveservices.azure.com%2F&client_id=${var.imds_identity_client_id}"
    headers         = [{ name = "Metadata", value = "true" }]
    useSystemProxy  = false
    fireAndForget   = false
    exitOnError     = true
    errorCondition  = "{#calloutResponse.status != 200}"
    errorStatusCode = "502"
    errorContent    = "Backend identity is unavailable"
    variables       = [{ name = "foundry.access_token", value = "{#jsonPath(#calloutResponse.content, '$.access_token')}", evaluateAsString = true }]
  })
  limit_steps = { for key, a in var.apis : key => [
    { name = "Synchronous request rate", enabled = true, policy = "rate-limit", configuration = jsonencode({
      async = false, addHeaders = true, errorStrategy = "BLOCK_ON_INTERNAL_ERROR"
      rate  = { key = "", useKeyOnly = false, limit = a.requests_per_minute, periodTime = 1, periodTimeUnit = "MINUTES" }
    }) },
    { name = "Synchronous request quota", enabled = true, policy = "quota", configuration = jsonencode({
      async = false, addHeaders = true, errorStrategy = "BLOCK_ON_INTERNAL_ERROR"
      quota = { key = "", useKeyOnly = false, limit = a.requests_per_day, periodTime = 1, periodTimeUnit = "DAYS" }
    }) }
  ] }
}
resource "apim_shared_policy_group" "limits" {
  for_each        = var.apis
  organization_id = var.organization_id
  environment_id  = var.environment_id
  hrid            = "${var.name_prefix}-limits-${each.key}"
  name            = "${var.name_prefix} ${each.key} request limits"
  description     = "Request counts only; not token limits or AI guardrails."
  api_type        = "PROXY"
  phase           = "REQUEST"
  steps           = local.limit_steps[each.key]
}
resource "apim_apiv4" "this" {
  for_each        = var.apis
  organization_id = var.organization_id
  environment_id  = var.environment_id
  hrid            = "${var.name_prefix}-api-${each.key}"
  name            = "${var.name_prefix} ${each.key} approved Foundry chat"
  description     = "Approved classic Azure OpenAI chat/completions proxy; no MCP or agent APIs."
  version         = "1.0"
  type            = "PROXY"
  state           = var.publish_apis ? "STARTED" : "STOPPED"
  visibility      = "PRIVATE"
  lifecycle_state = var.publish_apis ? "PUBLISHED" : "UNPUBLISHED"
  listeners       = [{ http = { type = "HTTP", entrypoints = [{ type = "http-proxy" }], paths = [{ path = each.value.context_path }] } }]
  endpoint_groups = [{
    name          = "Approved private Foundry target"
    type          = "http-proxy"
    load_balancer = { type = "ROUND_ROBIN" }
    endpoints = [{
      name                  = "Approved chat deployment"
      type                  = "http-proxy"
      inherit_configuration = false
      configuration         = jsonencode({ target = "${var.approved_backends[each.value.backend].openai_endpoint}openai/deployments/${var.approved_backends[each.value.backend].deployment_name}" })
    }]
  }]
  flow_execution = { mode = "DEFAULT", match_required = true }
  flows = [{
    name      = "Only POST at the approved chat/completions operation"
    enabled   = true
    selectors = [{ http = { type = "HTTP", path = "/chat/completions", path_operator = "EQUALS", methods = ["POST"] } }]
    request = [
      { name = "Reject wrong issuer audience missing expiry or role", enabled = true, policy = "policy-interrupt", condition = local.claim_rejection,
      configuration = jsonencode({ statusCode = 403, errorKey = "CONSUMER_NOT_AUTHORIZED", message = "Consumer is not authorized" }) },
      { name = "Request limits before identity calls", enabled = true, policy = "shared-policy-group-policy", configuration = jsonencode({ hrid = apim_shared_policy_group.limits[each.key].hrid }) },
      { name = "Remove consumer credentials and cookies", enabled = true, policy = "transform-headers",
      configuration = jsonencode({ removeHeaders = ["Authorization", "Proxy-Authorization", "api-key", "X-Gravitee-Api-Key", "Cookie", "baggage"] }) },
      { name = "Pin API version and discard consumer query", enabled = true, policy = "transform-queryparams",
      configuration = jsonencode({ clearAll = true, addQueryParameters = [{ name = "api-version", value = var.approved_backends[each.value.backend].api_version, appendToExistingArray = false }] }) },
      { name = "Acquire backend token from Azure VM IMDS", enabled = true, policy = "policy-http-callout", configuration = local.imds_configuration },
      { name = "Fail closed on missing token", enabled = true, policy = "policy-interrupt", condition = "{#context.attributes['foundry.access_token'] == null or #context.attributes['foundry.access_token'].isEmpty()}",
      configuration = jsonencode({ statusCode = 502, errorKey = "BACKEND_IDENTITY_UNAVAILABLE", message = "Backend identity is unavailable" }) },
      { name = "Set backend identity without forwarding consumer token", enabled = true, policy = "transform-headers",
      configuration = jsonencode({ addHeaders = [{ name = "Authorization", value = "Bearer {#context.attributes['foundry.access_token']}" }] }) }
    ]
    response = [{ name = "Remove credential response headers", enabled = true, policy = "transform-headers", configuration = jsonencode({ removeHeaders = ["Authorization", "api-key", "Set-Cookie"] }) }]
  }]
  plans = [{
    hrid       = "jwt"
    name       = "Explicitly subscribed Entra applications"
    type       = "API"
    mode       = "STANDARD"
    validation = "MANUAL"
    status     = var.publish_apis ? "PUBLISHED" : "STAGING"
    security   = { type = "JWT", configuration = local.jwt_configuration }
  }]
  analytics = {
    enabled = var.enable_analytics
    logging = {
      mode    = { endpoint = false, entrypoint = false }
      phase   = { request = false, response = false }
      content = { headers = false, payload = false, message_headers = false, message_payload = false, message_metadata = false }
    }
    otel_logs = { enabled = false }
    tracing = {
      enabled   = var.enable_tracing
      verbose   = false
      redaction = { default_replacement = "[REDACTED]", rules = [{ attribute_name_pattern = "*", masking_strategy = { type = "FULL", replacement = "[REDACTED]" } }] }
    }
  }
}
resource "apim_application" "this" {
  for_each        = var.applications
  organization_id = var.organization_id
  environment_id  = var.environment_id
  hrid            = "${var.name_prefix}-app-${each.key}"
  name            = each.value.name
  description     = "Existing Entra client association; no DCR or secret material."
  settings        = { app = { client_id = lower(each.value.client_id), type = "Existing Entra application" } }
}
resource "apim_subscription" "this" {
  for_each         = var.subscriptions
  organization_id  = var.organization_id
  environment_id   = var.environment_id
  hrid             = "${var.name_prefix}-subscription-${each.key}"
  api_hrid         = apim_apiv4.this[each.value.api].hrid
  plan_hrid        = "jwt"
  application_hrid = apim_application.this[each.value.application].hrid
  ending_at        = each.value.ending_at
}
