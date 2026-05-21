param(
  [switch] $NoWatch
)

$ErrorActionPreference = "Stop"

$port = 8000
$htmlFile = "Laboratory_6_AFrame_AR _Template.html"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ngrokApi = "http://127.0.0.1:4040/api/tunnels"

Set-Location $root

function Get-NgrokPath {
  $command = Get-Command ngrok -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  $wingetNgrok = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter ngrok.exe -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName

  if ($wingetNgrok) {
    return $wingetNgrok
  }

  throw "ngrok.exe was not found. Install it with: winget install --id Ngrok.Ngrok -e"
}

function Wait-ForHttp {
  param(
    [string] $Url,
    [int] $TimeoutSeconds = 15
  )

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    try {
      $response = Invoke-WebRequest -UseBasicParsing $Url -TimeoutSec 2
      if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
        return $true
      }
    } catch {
      Start-Sleep -Milliseconds 500
    }
  }

  return $false
}

$ngrokPath = Get-NgrokPath
$encodedHtml = [Uri]::EscapeDataString($htmlFile)
$localUrl = "http://127.0.0.1:$port/$encodedHtml"

Write-Host "Starting local AR server from:"
Write-Host "  $root"
Write-Host ""

if (Wait-ForHttp -Url $localUrl -TimeoutSeconds 2) {
  Write-Host "Local server is already running."
} else {
  Start-Process -WindowStyle Hidden -FilePath python -ArgumentList @("-m", "http.server", "$port", "--bind", "127.0.0.1") -WorkingDirectory $root

  if (-not (Wait-ForHttp -Url $localUrl -TimeoutSeconds 15)) {
    throw "The local server did not respond at $localUrl"
  }
}

Get-Process ngrok -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

$logPath = "ngrok-start.log"

Start-Process -WindowStyle Hidden -FilePath $ngrokPath -ArgumentList @("http", "$port", "--log", $logPath) -WorkingDirectory $root

$publicUrl = $null
$deadline = (Get-Date).AddSeconds(30)
while ((Get-Date) -lt $deadline -and -not $publicUrl) {
  try {
    $tunnels = Invoke-RestMethod $ngrokApi -TimeoutSec 2
    $publicUrl = ($tunnels.tunnels | Where-Object { $_.proto -eq "https" } | Select-Object -First 1 -ExpandProperty public_url)
  } catch {
    Start-Sleep -Milliseconds 700
  }
}

if (-not $publicUrl) {
  Write-Host "ngrok did not publish a tunnel. Last log lines:"
  if (Test-Path $logPath) {
    Get-Content $logPath -Tail 30
  }
  throw "Failed to start ngrok."
}

$publicPageUrl = "$publicUrl/$encodedHtml"

Write-Host ""
Write-Host "Local page:"
Write-Host "  $localUrl"
Write-Host ""
Write-Host "Public ngrok page:"
Write-Host "  $publicPageUrl"
Write-Host ""
Write-Host "Keep this window open while using the AR page."
Write-Host "Press Ctrl+C or close this window to stop watching. The background server/tunnel can be stopped from Task Manager if needed."

if ($NoWatch) {
  return
}

while ($true) {
  Start-Sleep -Seconds 3600
}
