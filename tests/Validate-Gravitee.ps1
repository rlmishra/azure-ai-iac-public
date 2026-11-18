[CmdletBinding()]
param([string]$Terraform = "terraform.exe")
$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path $PSScriptRoot -Parent
Push-Location $RepoRoot
try {
    & $Terraform fmt -check -recursive
    if ($LASTEXITCODE -ne 0) { throw "Terraform formatting failed" }
    foreach ($Root in @("gateways", "gateways/dev", "gateways/test", "gateways/prod")) {
        Push-Location (Join-Path $RepoRoot $Root)
        try {
            & $Terraform init -backend=false -input=false -lockfile=readonly
            if ($LASTEXITCODE -ne 0) { throw "Terraform init failed" }
            & $Terraform validate
            if ($LASTEXITCODE -ne 0) { throw "Terraform validation failed" }
            & $Terraform test
            if ($LASTEXITCODE -ne 0) { throw "Terraform tests failed" }
        } finally { Pop-Location }
    }
    # Requires Python 3 with jsonschema installed through approved enterprise tooling.
    python tests/check_gravitee_contracts.py --terraform $Terraform
    if ($LASTEXITCODE -ne 0) { throw "Gravitee policy contract verification failed" }
} finally { Pop-Location }
