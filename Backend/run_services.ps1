# Start the whole SOA backend, one PowerShell window per service.
# Usage (from the Backend folder):  .\run_services.ps1
# Add -Migrate to run migrations for the services that have a database before starting.
# NOTE: keep this file ASCII-only. Windows PowerShell 5.1 reads UTF-8 files without BOM as ANSI,
# so accented characters break the parser.
param([switch]$Migrate)

$backend = $PSScriptRoot
$python = Join-Path $backend '.venv\Scripts\python.exe'

# The registry must start first so the other services can register with it
$services = @(
    @{ Name = 'registry_service'; Port = 8010; HasDb = $true },
    @{ Name = 'auth_service'; Port = 8001; HasDb = $true },
    @{ Name = 'receipt_service'; Port = 8002; HasDb = $true },
    @{ Name = 'gateway'; Port = 8000; HasDb = $false }
)

foreach ($service in $services) {
    $dir = Join-Path $backend "services\$($service.Name)"
    if ($Migrate -and $service.HasDb) {
        Push-Location $dir
        & $python manage.py migrate --noinput
        Pop-Location
    }
    $command = "Set-Location '$dir'; `$host.UI.RawUI.WindowTitle = '$($service.Name) :$($service.Port)'; " +
        "& '$python' manage.py runserver 0.0.0.0:$($service.Port)"
    Start-Process powershell -ArgumentList '-NoExit', '-Command', $command
    Start-Sleep -Seconds 2
}

Write-Host 'Gateway (Flutter calls this): http://127.0.0.1:8000'
Write-Host 'Service catalog:              http://127.0.0.1:8000/api/services/'
Write-Host 'Registry:                     http://127.0.0.1:8010/registry/services/'
