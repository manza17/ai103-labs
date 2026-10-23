<#
.SYNOPSIS
  Borra el grupo de recursos de un lab y verifica que no quede nada facturando.
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\cleanup.ps1 -ResourceGroup rg-ai103-lab01
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup
)

$ErrorActionPreference = "Stop"

# 1. Sesión de Azure activa
$account = az account show --query "{suscripcion:name, usuario:user.name}" -o json 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "No hay sesión de Azure. Ejecutá 'az login' y volvé a intentar." -ForegroundColor Red
    exit 1
}
Write-Host "Suscripción: $($account.suscripcion) ($($account.usuario))" -ForegroundColor Cyan

# 2. ¿Existe el grupo?
if ((az group exists --name $ResourceGroup) -eq "false") {
    Write-Host "El grupo '$ResourceGroup' no existe (ya estaba borrado)." -ForegroundColor Yellow
} else {
    Write-Host "`nRecursos que se van a borrar en '$ResourceGroup':" -ForegroundColor Cyan
    az resource list --resource-group $ResourceGroup --query "[].{Nombre:name, Tipo:type}" -o table

    $ok = Read-Host "`n¿Borrar el grupo '$ResourceGroup' y todo su contenido? (s/n)"
    if ($ok -ne "s") {
        Write-Host "Cancelado. El lab NO está terminado hasta borrar el grupo." -ForegroundColor Red
        exit 1
    }

    Write-Host "Borrando (puede tardar unos minutos)..." -ForegroundColor Cyan
    az group delete --name $ResourceGroup --yes

    # 3. Verificación
    if ((az group exists --name $ResourceGroup) -eq "true") {
        Write-Host "ATENCIÓN: el grupo todavía existe. Revisalo en el portal." -ForegroundColor Red
        exit 1
    }
    Write-Host "OK: grupo '$ResourceGroup' borrado." -ForegroundColor Green
}

# 4. Panorama general: qué grupos quedan en la suscripción
Write-Host "`nGrupos de recursos que quedan en la suscripción:" -ForegroundColor Cyan
az group list --query "[].{Nombre:name, Ubicacion:location}" -o table

# 5. Recursos de Foundry en borrado temporal (no facturan, pero bloquean reusar el nombre 48 h)
Write-Host "`nRecursos de Foundry/Azure AI en borrado temporal (soft-delete):" -ForegroundColor Cyan
az cognitiveservices account list-deleted --query "[].{Nombre:name, Ubicacion:location}" -o table

Write-Host "`nListo. Marcá 'Limpieza verificada' en el README." -ForegroundColor Green
