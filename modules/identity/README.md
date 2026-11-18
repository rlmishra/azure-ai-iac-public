# identity

User-assigned workload identity and explicit data/monitoring role assignments.

No roles are assigned by default. Null principal_id selects the created workload identity; explicit values reference existing Entra object IDs. Scopes must be Azure resource IDs and roles must be on the reviewed data/monitoring allowlist. Directory users/groups/apps are not created.

Requires Terraform 1.17.2 and AzureRM 5.13.0. Configure the provider in the calling root. Inputs are typed and documented in `variables.tf`; outputs are in `outputs.tf`. See the repository root and environment roots for complete executable compositions.

Inputs: `name`, `resource_group_name`, `location`, `tags`, `assignments`.

Outputs: `id`, `client_id`, `principal_id`, `role_assignment_ids`.

The Azure roots now expose independent `workload_data_access` selections for vault secret read, blob read and Insights telemetry publishing, all false by default. The legacy combined flag remains supported; set it false before narrowing permissions. The existing assignment keys/roles/scopes remain stable. `access_grants` reports nonsecret effective role/principal/scope metadata for review, not evidence of host attachment or successful SDK authorization.
