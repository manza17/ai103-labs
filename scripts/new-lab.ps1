<#
.SYNOPSIS
  Crea la carpeta de un lab nuevo con Python 3.13, su venv y la plantilla de notas.
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\new-lab.ps1 -Name 02-chat-tools
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Name
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$labDir = Join-Path $root "labs\$Name"

if (Test-Path $labDir) {
    Write-Host "Ya existe: $labDir" -ForegroundColor Yellow
    exit 1
}

New-Item -ItemType Directory -Path $labDir | Out-Null
Set-Content -Path (Join-Path $labDir ".python-version") -Value "3.13"
Copy-Item (Join-Path $root "labs\01-chat-app\NOTES.md") (Join-Path $labDir "NOTES.md")

Push-Location $labDir
uv venv --python 3.13
Pop-Location

Write-Host "Lab creado en $labDir" -ForegroundColor Green
Write-Host "Siguiente: completar NOTES.md y agregar la fila en el README." -ForegroundColor Cyan
