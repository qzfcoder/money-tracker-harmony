param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
)

$ErrorActionPreference = 'Stop'
$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure([string]$message) {
  $script:failures.Add($message) | Out-Null
}

function Test-CommandAvailable([string]$name) {
  return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Assert-Pattern([string]$name, [string]$path, [string]$pattern) {
  if (-not (Test-Path $path)) {
    Add-Failure "$name missing file: $path"
    return
  }
  $text = Get-Content -Raw -Encoding UTF8 $path
  if ($text -notmatch $pattern) {
    Add-Failure "$name missing pattern '$pattern' in $path"
  }
}

Push-Location $Root
try {
  Write-Output "Harmony release test root: $Root"

  $status = & git status --short
  if ($LASTEXITCODE -ne 0) {
    Add-Failure 'git status failed'
  } elseif ($status) {
    Write-Output 'Git status: dirty'
    $status | ForEach-Object { Write-Output " - $_" }
  } else {
    Write-Output 'Git status: clean'
  }

  $releaseCheck = Join-Path $Root 'tools\release-check.ps1'
  if (Test-Path $releaseCheck) {
    & powershell -ExecutionPolicy Bypass -File $releaseCheck
    if ($LASTEXITCODE -ne 0) {
      Add-Failure 'tools\release-check.ps1 failed'
    }
  } else {
    Add-Failure 'tools\release-check.ps1 is missing'
  }

  $diffCheck = & cmd /c 'git diff --check 2>&1'
  if ($LASTEXITCODE -ne 0) {
    Add-Failure "git diff --check failed:`n$diffCheck"
  } else {
    Write-Output 'Whitespace check: passed'
  }

  Write-Output "hvigor available: $(Test-CommandAvailable 'hvigor')"
  Write-Output "ohpm available: $(Test-CommandAvailable 'ohpm')"
  Write-Output "hdc available: $(Test-CommandAvailable 'hdc')"

  Assert-Pattern 'Decimal parser' 'entry\src\main\ets\utils\NumberUtil.ets' 'normalizeAmountInput'
  Assert-Pattern 'Record amount parser' 'entry\src\main\ets\viewmodel\RecordViewModel.ets' 'NumberUtil\.toCentSafe'
  Assert-Pattern 'Custom CSV export' 'entry\src\main\ets\pages\DataExport.ets' 'ExportScope\.CUSTOM'
  Assert-Pattern 'Search result CSV export' 'entry\src\main\ets\pages\Search.ets' 'saveSearchCsv'
  Assert-Pattern 'Calendar monthly insight' 'entry\src\main\ets\pages\Calendar.ets' 'monthInsight'
  Assert-Pattern 'Asset liability summary' 'entry\src\main\ets\viewmodel\AssetsViewModel.ets' 'liabilityBalance'

  $registeredPages = Get-Content -Raw -Encoding UTF8 'entry\src\main\resources\base\profile\main_pages.json'
  if ($registeredPages -match 'AutoBookkeeping|AlipayImport') {
    Add-Failure 'Release-disabled pages are registered in main_pages.json'
  }

  if ($failures.Count -gt 0) {
    Write-Output 'HARMONY RELEASE TEST FAILED'
    foreach ($failure in $failures) {
      Write-Output " - $failure"
    }
    exit 1
  }

  Write-Output 'HARMONY RELEASE TEST PASSED'
  exit 0
} finally {
  Pop-Location
}
