# Phase 1 decisions (recorded before implementation)

- Workspace inspection found no existing repository source, Terraform configuration, or AGENTS.md. This is a new scaffold.
- Scope is Phase 1 only. Foundry, Gravitee, Ansible and pipeline implementation wait for the foundation validation gate. Their directories describe pending work, not deployable integrations.
- Query the official Terraform Registry and HashiCorp release endpoint, then pin AzureRM 5.13.0 and Terraform 1.17.2, the versions returned on 2026-11-13. Verify resources and attributes against the installed binary schema. No Phase 1 requirement justifies AzAPI. Recheck support before Phase 2.
- One subscription, tenant and region per environment. No credentials, Azure state access, approved regional list, network allocation, landing-zone policy IDs or Entra principal IDs are supplied. Examples are illustrative, not organizational approval.
- Existing landing-zone connectivity supplies outbound inspection, private build/automation agents, DNS forwarding and administrative connectivity. No public ingress, public service bypass, NAT gateway, hub peering, firewall or public admin jump host is provisioned.
- Separate workload and private-endpoint subnets. Workload NSG permits caller-specified HTTPS from trusted networks, Azure platform DNS, and HTTPS to private endpoints. Other traffic is denied. Endpoint NSG admits HTTPS from workload/explicit trusted networks only.
- Foundation owns resource group, network, Key Vault, storage, identities, monitoring, private endpoints and explicit resource-scoped RBAC. It does not manage secrets, federated CI identities or role assignments at subscription scope.
- Key Vault and storage use Azure-managed encryption at rest. Customer-managed keys are a later organization-specific design requiring key lifecycle, recovery and identity decisions.
- Application Insights ingestion and Log Analytics query/ingestion are private via Azure Monitor Private Link Scope. Workloads need hub DNS forwarding for Azure Monitor's shared private DNS zones. No telemetry validation is possible without deployment.
- Entra integrations use pre-existing object IDs, avoiding unnecessary Microsoft Graph privileges. No blanket Contributor or Owner grants. AzureRM authenticates via caller-configured CLI or OIDC; workload identity is created without secrets.
- Production deletion/retention behavior, recovery objectives and replication choice require enterprise review before deployment. Terraform state is external, encrypted and access controlled; backend configuration is provided during initialization.
- All local Terraform tests use mocked providers. They test plans and input guardrails without Azure credentials; they do not establish Azure deployment feasibility.
