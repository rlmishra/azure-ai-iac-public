# security

Private RBAC Key Vault, private keyless storage and optional existing RG policy assignments.

Azure-managed service encryption and storage infrastructure encryption are enabled. Key Vault and storage prevent_destroy protects against Terraform replacement/destruction while the blocks remain. No secret values or storage data objects are managed. Only deny/audit policies without remediation identities are supported by this module.

Requires Terraform 1.17.2 and AzureRM 5.13.0. Configure the provider in the calling root. Inputs are typed and documented in `variables.tf`; outputs are in `outputs.tf`. See the repository root and environment roots for complete executable compositions.

Inputs: `name`, `resource_group_name`, `location`, `tags`, `tenant_id`, `key_vault_name`, `storage_account_name`, `storage_replication_type`, `policy_assignments`, `resource_group_id`.

Outputs: `key_vault_id`, `key_vault_uri`, `storage_account_id`, `blob_service_id`, `storage_blob_endpoint`, `posture`.
