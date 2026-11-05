# Khởi động toàn bộ backend SOA, mỗi service một cửa sổ PowerShell riêng.
# Cách dùng (từ thư mục Backend):  .\run_services.ps1
# Thêm -Migrate để chạy migrate cho các service có database trước khi khởi động.
param([switch]$Migrate)

$backend = $PSScriptRoot
$python = Join-Path $backend '.venv\Scripts\python.exe'

# Registry phải chạy đầu tiên để các service khác đăng ký được
$services = @(
    @{ Name = 'registry_service'; Port = 8010; HasDb = $true },
    @{ Name = 'auth_service'; Port = 8001; HasDb = $true },
    @{ Name = 'receipt_service'; Port = 8002; HasDb = $true },
    @{ Name = 'gateway'; Port = 8000; HasDb = $false }
)

foreach ($service in $services) {
    $dir = Join-Path $backend "services\$($service.Name)"
    if ($Migrate -and $service.HasDb) {
        & $python (Join-Path $dir 'manage.py') migrate --noinput
    }
    $command = "Set-Location '$dir'; `$host.UI.RawUI.WindowTitle = '$($service.Name) :$($service.Port)'; " +
        "& '$python' manage.py runserver 0.0.0.0:$($service.Port)"
    Start-Process powershell -ArgumentList '-NoExit', '-Command', $command
    Start-Sleep -Seconds 2
}

Write-Host 'Gateway:         http://127.0.0.1:8000  (Flutter gọi vào đây)'
Write-Host 'Danh mục service: http://127.0.0.1:8000/api/services/'
Write-Host 'Registry:        http://127.0.0.1:8010/registry/services/'
