# monitoring

Private Log Analytics, workspace-based Application Insights, AMPLS and explicit diagnostic targets.

All ingestion/query and scope access are private; local auth is disabled. The networking module creates the AMPLS endpoint after scoped-service links finish. Pass only categories supported by the actual target. Sensitive connection-string output must be combined with an Entra-enabled SDK credential. No alert recipients are assumed.

Requires Terraform 1.17.2 and AzureRM 5.13.0. Configure the provider in the calling root. Inputs are typed and documented in `variables.tf`; outputs are in `outputs.tf`. See the repository root and environment roots for complete executable compositions.

Inputs: `name`, `resource_group_name`, `location`, `tags`, `retention_in_days`, `diagnostic_targets`.

Outputs: `workspace_id`, `application_insights_id`, `application_insights_connection_string`, `private_link_scope_id`, `posture`.
