param(
  [string]$Url = 'http://127.0.0.1:5173/#/home',
  [string]$TestPath = 'test/features/scanner/presentation/widgets/scan_tab_responsive_matrix_test.dart',
  [string]$OutRoot = 'qa-artifact/scan-layout-strict-overlap'
)

$ErrorActionPreference = 'Stop'

function Write-Info {
  param([string]$Message)
  Write-Output "[scan-overlap-pass] $Message"
}

function Get-Viewports {
  return @(
    @{Name = '360x740'; Width = 360; Height = 740; Transition = $true; StrictTiny = $false},
    @{Name = '390x844'; Width = 390; Height = 844; Transition = $true; StrictTiny = $false},
    @{Name = '430x932'; Width = 430; Height = 932; Transition = $true; StrictTiny = $false},
    @{Name = '844x390'; Width = 844; Height = 390; Transition = $true; StrictTiny = $false},
    @{Name = '1024x768'; Width = 1024; Height = 768; Transition = $true; StrictTiny = $false},
    @{Name = '340x260'; Width = 340; Height = 260; Transition = $true; StrictTiny = $true},
    @{Name = '320x240'; Width = 320; Height = 240; Transition = $true; StrictTiny = $true}
  )
}

function Assert-Endpoint {
  param([string]$TargetUrl)

  $uri = [uri]$TargetUrl
  $hostName = $uri.Host
  $port = if ($uri.Port) { $uri.Port } else { 80 }
  if (-not (Test-NetConnection -ComputerName $hostName -Port $port -WarningAction SilentlyContinue).TcpTestSucceeded) {
    throw "Target is not reachable: $TargetUrl"
  }
  Write-Info "Endpoint reachable: $TargetUrl"
}

function Capture-Image {
  param(
    [Parameter(Mandatory = $true)] [string]$ViewportSpec,
    [Parameter(Mandatory = $true)] [string]$TargetUrl,
    [Parameter(Mandatory = $true)] [string]$OutputPath,
    [int]$WaitMs = 1200
  )

  & npx playwright@1.60.0 screenshot --viewport-size=$ViewportSpec --wait-for-selector=flutter-view --timeout=60000 --wait-for-timeout=$WaitMs $TargetUrl $OutputPath
}

function Add-QueryParam {
  param(
    [Parameter(Mandatory = $true)] [string]$BaseUrl,
    [Parameter(Mandatory = $true)] [string]$Name,
    [Parameter(Mandatory = $true)] [string]$Value
  )

  $separator = if ($BaseUrl.Contains('?')) { '&' } else { '?' }
  return "$BaseUrl$separator$Name=$([uri]::EscapeDataString($Value))"
}

function Get-MinArtifactBytes {
  param(
    [Parameter(Mandatory = $true)] [hashtable]$Viewport
  )

  if ($Viewport.StrictTiny) {
    return 512
  }

  return 1024
}

function Assert-ArtifactFile {
  param(
    [Parameter(Mandatory = $true)] [string]$Path,
    [int]$MinBytes = 1024
  )

  if (-not (Test-Path -Path $Path)) {
    throw "Missing artifact: $Path"
  }

  $item = Get-Item -Path $Path
  if ($item.Length -lt $MinBytes) {
    throw "Artifact too small ($($item.Length) bytes): $Path"
  }
}

function Write-ContactSheet {
  param(
    [Parameter(Mandatory = $true)] [string]$Root,
    [Parameter(Mandatory = $true)] [array]$Results
  )

  function Escape-Html {
    param([string]$Text)
    if ($null -eq $Text) {
      return ''
    }
    return $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;')
  }

  $outFile = Join-Path $Root 'scan-layout-overlap-contact-sheet.html'
  $rows = New-Object System.Text.StringBuilder
  [void]$rows.AppendLine('<section>')
  [void]$rows.AppendLine('  <h2>Matrix</h2>')
  [void]$rows.AppendLine('  <div class="grid">')
  foreach ($result in $Results) {
    $name = Escape-Html -Text $result.viewport
    $matrixPath = Escape-Html -Text ('matrix/' + $result.viewport + '.png')
    [void]$rows.AppendLine("    <figure><figcaption>$name</figcaption><img src=`"$matrixPath`" alt=`"Matrix $name`"/></figure>")
  }
  [void]$rows.AppendLine('  </div>')
  [void]$rows.AppendLine('</section>')

  [void]$rows.AppendLine('<section>')
  [void]$rows.AppendLine('  <h2>Transitions</h2>')
  [void]$rows.AppendLine('  <div class="grid">')
  foreach ($result in $Results) {
    foreach ($transition in $result.transitions) {
      $vpName = Escape-Html -Text $result.viewport
      $phase = Escape-Html -Text $transition.phase
      $transitionPath = Escape-Html -Text (
        'transitions/' + $result.viewport + '-' + $transition.phase + '.png'
      )
      [void]$rows.AppendLine(
        "    <figure><figcaption>${vpName} - $phase</figcaption><img src=`"$transitionPath`" alt=`"$vpName transition $phase`"/></figure>"
      )
    }
  }
  [void]$rows.AppendLine('  </div>')
  [void]$rows.AppendLine('</section>')

  $rowsText = $rows.ToString()
  $html = @"
<!doctype html>
<html>
  <head>
    <meta charset=`"utf-8`" />
    <title>Scan Layout Overlap Contact Sheet</title>
    <style>
      body { font-family: Arial, sans-serif; margin: 20px; color: #111; }
      h1, h2 { margin: 0 0 12px; }
      .grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
        gap: 12px;
        margin-bottom: 24px;
      }
      figure { margin: 0; border: 1px solid #ddd; border-radius: 8px; padding: 8px; background: #fafafa; }
      figcaption { font-size: 12px; color: #333; margin-bottom: 6px; }
      img { width: 100%; height: auto; display: block; }
      .meta { font-size: 12px; color: #666; margin-bottom: 18px; }
    </style>
  </head>
  <body>
    <h1>Scan Layout Overlap Contact Sheet</h1>
    <div class="meta">Generated $(Get-Date). Open to review matrix + transitions. Flag any overlap/clipping by eye before merge.</div>
$rowsText
  </body>
</html>
"@

  $html | Set-Content -Path $outFile -Encoding UTF8
  Write-Info "Contact sheet written: $outFile"
}

function Assert-ReportIntegrity {
  param(
    [Parameter(Mandatory = $true)] [string]$Path,
    [Parameter(Mandatory = $true)] [array]$ExpectedViewports,
    [int]$ExpectedTransitionCount = 3
  )

  $parsed = Get-Content $Path -Raw | ConvertFrom-Json
  if ($parsed.status -ne 'pass') {
    throw "Report status is not pass: $Path"
  }

  if ($parsed.results.Count -ne $ExpectedViewports.Count) {
    throw "Report results count mismatch. Expected $($ExpectedViewports.Count), got $($parsed.results.Count)"
  }

  foreach ($expect in $ExpectedViewports) {
    $match = $parsed.results | Where-Object { $_.viewport -eq $expect.Name }
    if (-not $match) {
      throw "Missing viewport in report: $($expect.Name)"
    }
    $minBytes = Get-MinArtifactBytes -Viewport $expect
    Assert-ArtifactFile -Path $match.matrix -MinBytes $minBytes

    if ($expect.Transition) {
      if (($match.transitions.Count) -ne $ExpectedTransitionCount) {
        throw "Transition capture count mismatch for $($expect.Name). Expected $ExpectedTransitionCount, got $($match.transitions.Count)"
      }
      if (-not $match.transitionCaptured) {
        throw "Transition capture flag false for $($expect.Name)"
      }
      foreach ($transition in $match.transitions) {
        Assert-ArtifactFile -Path $transition.path -MinBytes $minBytes
      }
    } elseif ($match.transitions.Count -gt 0) {
      throw "Expected no transitions for $($expect.Name), but found $($match.transitions.Count)"
    }
  }
}

$root = Split-Path -Path $PSScriptRoot -Parent
$matrixDir = Join-Path $root "$OutRoot/matrix"
$transitionDir = Join-Path $root "$OutRoot/transitions"
$reportPath = Join-Path $root "$OutRoot/report.json"
$testOutputPath = Join-Path $root "$OutRoot/test-output.jsonl"

foreach ($dir in @($matrixDir, $transitionDir)) {
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
  }
}

Assert-Endpoint -TargetUrl $Url

Write-Info "Running strict overlap/geometry regression tests: $TestPath"
& flutter test --no-pub --reporter json $TestPath | Set-Content -Path $testOutputPath
if ($LASTEXITCODE -ne 0) {
  throw "Geometry test failed (exit code $LASTEXITCODE). Inspect $testOutputPath"
}
Write-Info 'Geometry regression test passed.'

$viewports = Get-Viewports
$results = @()

foreach ($vp in $viewports) {
  $size = "$($vp.Width),$($vp.Height)"
  $outPath = Join-Path $matrixDir "$($vp.Name).png"
  Write-Info "Capturing static matrix @ $($vp.Name)"
  Capture-Image -ViewportSpec $size -TargetUrl $Url -OutputPath $outPath
  if ($LASTEXITCODE -ne 0) {
    throw "Matrix capture failed for $($vp.Name)."
  }
  $minBytes = Get-MinArtifactBytes -Viewport $vp
  Assert-ArtifactFile -Path $outPath -MinBytes $minBytes

  $transitions = @()
  Write-Info "Transition capture enabled for $($vp.Name): $($vp.Transition)"
  if ($vp.Transition) {
    foreach ($phase in @(
      @{Name = 'early'; Delay = 300},
      @{Name = 'mid'; Delay = 1200},
      @{Name = 'late'; Delay = 2100}
    )) {
      $transPath = Join-Path $transitionDir "$($vp.Name)-$($phase.Name).png"
      Write-Info "Capturing transition $($phase.Name) @ $($vp.Name)"
      $transitionUrl = Add-QueryParam -BaseUrl $Url -Name 'qa_camera_status' -Value 'unavail-ready'
      Capture-Image -ViewportSpec $size -TargetUrl $transitionUrl -OutputPath $transPath -WaitMs $phase.Delay
      if ($LASTEXITCODE -ne 0) {
        throw "Transition capture failed for $($vp.Name) $($phase.Name)."
      }
      Assert-ArtifactFile -Path $transPath -MinBytes $minBytes
      $transitions += [pscustomobject]@{
        phase = $phase.Name
        delayMs = $phase.Delay
        path = $transPath
      }
    }
  }

  $results += [pscustomobject]@{
    viewport = $vp.Name
    width = $vp.Width
    height = $vp.Height
    strictTiny = $vp.StrictTiny
    matrix = $outPath
    transitionCaptured = $vp.Transition
    transitions = $transitions
  }
}

$report = [pscustomobject]@{
  timestamp = (Get-Date).ToString('o')
  status = 'pass'
  script = $MyInvocation.MyCommand.Name
  matrixTest = $TestPath
  url = $Url
  results = $results
}

Write-ContactSheet -Root (Join-Path $root $OutRoot) -Results $results
$report | ConvertTo-Json -Depth 6 | Set-Content -Path $reportPath
Assert-ReportIntegrity -Path $reportPath -ExpectedViewports $viewports
Write-Info "Saved overlap report: $reportPath"
Write-Info "Complete. Matrix artifacts in $matrixDir, transition artifacts in $transitionDir"
