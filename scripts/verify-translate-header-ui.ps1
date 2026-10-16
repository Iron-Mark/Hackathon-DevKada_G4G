#Requires -Version 7.0

param(
  [string]$Url = 'http://127.0.0.1:5173',
  [string]$Widths = '768,1024,1366,1920',
  [int]$Height = 900,
  [object]$Tabs = @('translate'),
  [string]$OutputDir = 'test-results/ui-verify',
  [switch]$SkipTests
)

$ErrorActionPreference = 'Stop'

function Write-Info {
  param([string]$Message)
  Write-Output "[ui-verify] $Message"
}

function Write-Warn {
  param([string]$Message)
  Write-Warning "[ui-verify] $Message"
}

function Parse-Widths {
  param([string]$RawWidths)

  $widths = New-Object System.Collections.Generic.List[int]
  $parts = $RawWidths -split '[,\s]+' | Where-Object { $_ }

  foreach ($part in $parts) {
    $value = 0
    if (-not [int]::TryParse($part, [ref]$value)) {
      throw "Invalid width value '$part' in -Widths. Use comma-separated integers like 768,1024,1366,1920."
    }
    if ($value -lt 320) {
      throw "Invalid width '$value'. Widths below 320 are not supported."
    }
    if (-not $widths.Contains($value)) {
      [void]$widths.Add($value)
    }
  }

  if ($widths.Count -eq 0) {
    throw 'No valid widths provided. Provide at least one valid positive integer.'
  }

  return @($widths | Sort-Object)
}

function Parse-Tabs {
  param($RawTabs)

  $tabValues = if ($RawTabs -is [System.Collections.IEnumerable] -and $RawTabs -isnot [string]) {
    $RawTabs
  } else {
    $RawTabs -split '[,\s]+' | Where-Object { $_ }
  }
  $normalized = New-Object System.Collections.Generic.List[string]
  $seen = New-Object System.Collections.Generic.HashSet[string]
  foreach ($tab in $tabValues) {
    if ($null -ne $tab) {
      $value = $tab.ToString().Trim().ToLowerInvariant()
      if ($value -and -not $seen.Contains($value)) {
        [void]$normalized.Add($value)
        [void]$seen.Add($value)
      }
    }
  }

  if ($normalized.Count -eq 0) {
    return ,@('translate')
  }

  return ,@($normalized.ToArray())
}

function Build-TabUrl {
  param(
    [string]$BaseUrl,
    [string]$Tab
  )

  $uri = [uri]$BaseUrl
  $rootUrl = $uri.GetLeftPart([System.UriPartial]::Authority).TrimEnd('/')
  $path = '/#/home'
  if (-not [string]::IsNullOrWhiteSpace($Tab)) {
    return "${rootUrl}${path}?tab=$([uri]::EscapeDataString($Tab))"
  }
  return "${rootUrl}${path}"
}

function Get-Port {
  param([uri]$Uri)

  if ($Uri.IsDefaultPort) {
    switch ($Uri.Scheme) {
      'https' { return 443 }
      default { return 80 }
    }
  }
  return $Uri.Port
}

$root = Resolve-Path $PSScriptRoot/..
$parsedWidths = Parse-Widths -RawWidths $Widths
$logPrefix = 'translate-header'
$safeTabs = @(Parse-Tabs -RawTabs $Tabs)
if ($safeTabs.Count -eq 0) {
  Write-Warn 'No tabs were provided in -Tabs. Falling back to translate only.'
  $safeTabs = @('translate')
}

if (!(Test-Path $OutputDir)) {
  New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

if (-not $SkipTests) {
  Write-Info 'Running Flutter density tests for the translate header.'
  & flutter test --no-pub test/features/home/presentation/widgets/translate_density_test.dart
  if ($LASTEXITCODE -ne 0) {
    throw "flutter test failed (exit code $LASTEXITCODE)."
  }
  Write-Info 'Flutter density tests passed.'
} else {
  Write-Warn 'Skipping Flutter tests due to -SkipTests.'
}

$uri = [uri]$Url
$uriBase = $uri.GetLeftPart([System.UriPartial]::Authority)
$previewHost = $uri.Host
$port = Get-Port -Uri $uri

Write-Info "Ensuring preview URL is reachable: $uriBase"
$isReachable = $false
try {
  $isReachable = (Test-NetConnection -ComputerName $previewHost -Port $port -WarningAction SilentlyContinue).TcpTestSucceeded
} catch {
  $isReachable = $false
}

$serverWasStarted = $false
$pythonProc = $null
if (-not $isReachable) {
  $webBuild = Join-Path $root 'build/web'
  if (-not (Test-Path $webBuild)) {
    Write-Info 'build/web not found. Running flutter build web --release.'
    & flutter build web --release
    if ($LASTEXITCODE -ne 0) {
      throw "flutter build web --release failed (exit code $LASTEXITCODE)."
    }
  }

  Write-Info "Starting local static preview on port $port."
  $pythonProc = Start-Process -FilePath python -WindowStyle Hidden -ArgumentList @(
    '-m',
    'http.server',
    $port.ToString(),
    '--directory',
    (Join-Path $root 'build/web')
  ) -PassThru
  $serverWasStarted = $true
  Start-Sleep -Milliseconds 1200

  $attempt = 0
  while (-not (Test-NetConnection -ComputerName $previewHost -Port $port -WarningAction SilentlyContinue).TcpTestSucceeded -and $attempt -lt 40) {
    Start-Sleep -Milliseconds 500
    $attempt++
  }
  if (-not (Test-NetConnection -ComputerName $previewHost -Port $port -WarningAction SilentlyContinue).TcpTestSucceeded) {
    if ($pythonProc) {
      Stop-Process -Id $pythonProc.Id -ErrorAction SilentlyContinue
    }
    throw "Preview server did not become reachable on port $port."
  }
}

try {
  foreach ($tab in $safeTabs) {
    $targetUrl = Build-TabUrl -BaseUrl $uriBase -Tab $tab
    foreach ($w in $parsedWidths) {
      $safeTab = $tab -replace '[^\w-]', '-'
      $outFile = Join-Path $root "$OutputDir/$logPrefix-$safeTab-$w.png"
      $viewport = "$w,$Height"
      Write-Info "Capturing $tab header @ ${w}x$Height -> $outFile"
      & npx playwright screenshot --viewport-size=$viewport $targetUrl $outFile --wait-for-timeout=8000
      if ($LASTEXITCODE -ne 0) {
        throw "Playwright screenshot failed for tab $tab at width $w (exit code $LASTEXITCODE)."
      }
    }
  }
} finally {
  if ($serverWasStarted -and $pythonProc -and -not $pythonProc.HasExited) {
    Stop-Process -Id $pythonProc.Id -ErrorAction SilentlyContinue
    Write-Info 'Stopped temporary static preview server.'
  }
}

Write-Info "Verification complete. Screenshots in $OutputDir"
