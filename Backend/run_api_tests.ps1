# Chay bo kiem thu API tu dong cua ExpenseSnap va luu ket qua theo ten tester.
# Cach dung (tu thu muc Backend, backend da chay bang run_services.ps1):
#   .\run_api_tests.ps1 -Tester "TranQuocTuan"
#   .\run_api_tests.ps1 -Tester "TranQuocTuan" -SkipReceiptDown   # bo qua lan 2
param(
    [Parameter(Mandatory = $true)][string]$Tester,
    [switch]$SkipReceiptDown
)

$ErrorActionPreference = 'Stop'
$py = Join-Path $PSScriptRoot '.venv\Scripts\python.exe'
if (-not (Test-Path $py)) { throw "Khong tim thay $py. Hay tao .venv va cai requirements truoc." }

$testDir = Join-Path $PSScriptRoot 'api_tests'
if (-not (Test-Path (Join-Path $testDir '.env.test'))) {
    throw 'Chua co api_tests\.env.test. Copy tu .env.test.example va dien JWT_SIGNING_KEY, TEST_USER_ID.'
}

$stamp = Get-Date -Format 'yyyyMMdd_HHmm'
$out = Join-Path $testDir "ket_qua\${stamp}_$Tester"
New-Item -ItemType Directory -Force -Path $out | Out-Null
Push-Location $testDir
try {
    Write-Host '== Lan 1: toan bo bo test (receipt-service dang chay)' -ForegroundColor Cyan
    & $py -m pytest -v -p no:cacheprovider `
        --junitxml="$out\lan1.xml" --html="$out\lan1.html" --self-contained-html
    $code1 = $LASTEXITCODE

    if (-not $SkipReceiptDown) {
        Write-Host ''
        Write-Host '== Lan 2: dong cua so receipt_service :8002, cho 15 giay roi nhan Enter' -ForegroundColor Cyan
        Read-Host | Out-Null
        $env:RECEIPT_DOWN = '1'
        & $py -m pytest -v -p no:cacheprovider -k TC_GW_06 --junitxml="$out\lan2_tat_receipt.xml"
        Remove-Item Env:RECEIPT_DOWN
        Write-Host 'Nho bat lai receipt-service (hoac chay lai run_services.ps1).' -ForegroundColor Yellow
    }

    Write-Host ''
    Write-Host "Ket qua luu tai: $out  (mo lan1.html de xem)" -ForegroundColor Green
    exit $code1
}
finally {
    Pop-Location
}
