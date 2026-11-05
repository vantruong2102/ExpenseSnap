# Run the Flutter app on any device (Android emulator, real Android phone, web, Windows).
# For every connected Android device it runs `adb reverse tcp:8000 tcp:8000`, so the app on the
# device reaches the backend gateway on this laptop at http://127.0.0.1:8000 (no laptop IP needed).
#
# Usage (from the Frontend folder):
#   .\run_app.ps1                       # same as `flutter run`
#   .\run_app.ps1 -d cy9p45cebu6deiea   # any `flutter run` arguments are passed through
#
# NOTE: keep this file ASCII-only (Windows PowerShell 5.1 reads UTF-8 without BOM as ANSI).

$gatewayPort = 8000

$adb = (Get-Command adb -ErrorAction SilentlyContinue).Source
if (-not $adb) {
    $sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } elseif ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { "$env:LOCALAPPDATA\Android\Sdk" }
    $candidate = Join-Path $sdk 'platform-tools\adb.exe'
    if (Test-Path $candidate) { $adb = $candidate }
}

if ($adb) {
    $devices = & $adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\tdevice$' } | ForEach-Object { ($_ -split '\t')[0] }
    foreach ($device in $devices) {
        & $adb -s $device reverse "tcp:$gatewayPort" "tcp:$gatewayPort" | Out-Null
        Write-Host "adb reverse tcp:$gatewayPort -> laptop:$gatewayPort on $device"
    }
    $blocked = & $adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\t(unauthorized|offline)$' }
    foreach ($line in $blocked) {
        Write-Warning "Device not ready: $line (unlock the phone and allow USB debugging, or run 'adb kill-server')"
    }
} else {
    Write-Warning 'adb not found: Android devices will not reach the backend. Install Android SDK platform-tools.'
}

Set-Location $PSScriptRoot
flutter run @args
