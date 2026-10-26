<#
.SYNOPSIS
  Crea la carpeta de un lab nuevo con la plantilla de notas (usa el venv compartido de la raíz).
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\new-lab.ps1 -Name 03-optimizar
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
Copy-Item (Join-Path $root "scripts\NOTES-template.md") (Join-Path $labDir "NOTES.md")

Write-Host "Lab creado en $labDir" -ForegroundColor Green
Write-Host "Siguiente: copiar los archivos del lab, instalar su requirements.txt en el venv de la raíz y agregar la fila en el README." -ForegroundColor Cyan
