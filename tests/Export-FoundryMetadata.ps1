[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$EnvironmentPath,
    [Parameter(Mandatory=$true)][string]$OutputPath,
    [string]$Terraform = "terraform.exe"
)
$ErrorActionPreference = "Stop"
# Run manually only with approved state access after a separately approved Phase 2 deployment.
Push-Location $EnvironmentPath
try {
    $Raw = & $Terraform output -json foundry
    if ($LASTEXITCODE -ne 0) { throw "Cannot read approved Foundry output" }
    $Foundry = $Raw | ConvertFrom-Json
    if ($null -eq $Foundry -or $null -eq $Foundry.deployments -or @($Foundry.deployments.PSObject.Properties).Count -eq 0) {
        throw "No deployed Foundry models found; do not fabricate gateway backend metadata"
    }
    $Deployments = @{}
    foreach ($Deployment in $Foundry.deployments.PSObject.Properties) {
        $Deployments[$Deployment.Name] = @{
            phase2_deployment_id = $Deployment.Value.id
            model = $Deployment.Value.model
            sku = $Deployment.Value.sku
            capacity = $Deployment.Value.capacity
        }
    }
    $Metadata = @{
        account_id = $Foundry.account_id
        openai_endpoint = $Foundry.openai_endpoint
        deployments = $Deployments
        approval_status = "NOT_APPROVED_BY_EXPORT"
    }
    # Contains no tokens/keys. Still classify and protect endpoint/deployment metadata.
    $Metadata | ConvertTo-Json -Depth 12 | Set-Content -Encoding utf8 -Path $OutputPath
} finally { Pop-Location }
