[CmdletBinding()]
param([string]$Terraform = "terraform.exe")
$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path $PSScriptRoot -Parent
function Invoke-Terraform {
    param([string[]]$Arguments)
    & $Terraform @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Terraform failed with exit code $LASTEXITCODE" }
}
Push-Location $RepoRoot
try {
    Invoke-Terraform -Arguments @("fmt", "-check", "-recursive")
    foreach ($Root in @(".", "environments/dev", "environments/test", "environments/prod")) {
        Push-Location (Join-Path $RepoRoot $Root)
        try {
            Invoke-Terraform -Arguments @("init", "-backend=false", "-input=false")
            Invoke-Terraform -Arguments @("validate")
            Invoke-Terraform -Arguments @("test")
        } finally { Pop-Location }
    }
} finally { Pop-Location }
