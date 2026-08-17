param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure([string]$message) {
  $script:failures.Add($message) | Out-Null
}

function Read-Json([string]$path) {
  try {
    return Get-Content -Raw -Encoding UTF8 $path | ConvertFrom-Json
  } catch {
    Add-Failure "Invalid JSON: $path"
    return $null
  }
}

function Assert-NoMatches([string]$name, [string]$path, [string[]]$patterns) {
  $files = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue
  foreach ($pattern in $patterns) {
    $matches = $files | Select-String -Pattern $pattern -ErrorAction SilentlyContinue
    foreach ($match in $matches) {
      Add-Failure "$name matched '$pattern' at $($match.Path):$($match.LineNumber)"
    }
  }
}

function Assert-DecimalInput([string]$file, [string]$binding) {
  if (-not (Test-Path $file)) {
    Add-Failure "Decimal input file missing: $file"
    return
  }
  $text = Get-Content -Raw -Encoding UTF8 $file
  $escapedBinding = [regex]::Escape($binding)
  $pattern = "TextInput\s*\(\s*\{\s*text:\s*$escapedBinding[\s\S]*?\.onChange"
  $match = [regex]::Match($text, $pattern)
  if (-not $match.Success) {
    Add-Failure "Decimal input binding not found: $binding in $file"
    return
  }
  if ($match.Value -notmatch 'InputType\.NUMBER_DECIMAL') {
    Add-Failure "Decimal input missing NUMBER_DECIMAL: $binding in $file"
  }
}

Push-Location $Root
try {
  $modulePath = Join-Path $Root 'entry/src/main/module.json5'
  $pagesPath = Join-Path $Root 'entry/src/main/resources/base/profile/main_pages.json'
  $stringsPath = Join-Path $Root 'entry/src/main/resources/base/element/string.json'
  $routesPath = Join-Path $Root 'entry/src/main/ets/constants/RouteConstants.ets'
  $featureFlagsPath = Join-Path $Root 'entry/src/main/ets/constants/FeatureFlags.ets'
  $etsRoot = Join-Path $Root 'entry/src/main/ets'

  $module = Read-Json $modulePath
  $pagesJson = Read-Json $pagesPath
  $null = Read-Json $stringsPath

  if ($module -ne $null) {
    if ($module.module.requestPermissions.Count -ne 0) {
      Add-Failure 'module.json5 requestPermissions must be empty for this release'
    }
    if ($module.module.PSObject.Properties.Name -contains 'extensionAbilities') {
      Add-Failure 'module.json5 must not declare extensionAbilities for this release'
    }
  }

  if ($pagesJson -ne $null) {
    foreach ($page in $pagesJson.src) {
      $pageFile = Join-Path $etsRoot ($page + '.ets')
      if (-not (Test-Path $pageFile)) {
        Add-Failure "Registered page file missing: $page"
      }
    }
  }

  if ((Test-Path $routesPath) -and $pagesJson -ne $null) {
    $routeText = Get-Content -Raw -Encoding UTF8 $routesPath
    $routes = [regex]::Matches($routeText, "'([^']+)'") | ForEach-Object { $_.Groups[1].Value }
    foreach ($route in $routes) {
      if ($pagesJson.src -notcontains $route) {
        Add-Failure "Route is not registered in main_pages.json: $route"
      }
    }
  }

  if (Test-Path $featureFlagsPath) {
    $featureFlagsText = Get-Content -Raw -Encoding UTF8 $featureFlagsPath
    if ($featureFlagsText -notmatch 'AUTO_BOOKKEEPING_VISIBLE:\s*boolean\s*=\s*false') {
      Add-Failure 'AUTO_BOOKKEEPING_VISIBLE must be false for this release'
    }
    if ($featureFlagsText -notmatch 'ALIPAY_BILL_IMPORT_VISIBLE:\s*boolean\s*=\s*false') {
      Add-Failure 'ALIPAY_BILL_IMPORT_VISIBLE must be false for this release'
    }
  } else {
    Add-Failure 'FeatureFlags.ets is missing'
  }

  $sensitivePatterns = @(
    '隐私',
    '用户协议',
    'Privacy',
    'privacy',
    '通知',
    '短信',
    '订阅',
    'Notification',
    'notification',
    '\bSMS\b',
    '\bsms\b',
    '@ohos\.screenshot',
    'screenshot\.pick',
    'terminateSelf',
    'ReminderService',
    'NotificationBookkeepingSubscriber',
    'AutoNotificationPayload',
    'autoNotification',
    'autoSms'
  )
  Assert-NoMatches 'Release-sensitive source scan' (Join-Path $Root 'entry/src/main/*') $sensitivePatterns

  $etsFiles = Get-ChildItem -Path $etsRoot -Recurse -File -Filter '*.ets'
  $decimalMatches = $etsFiles | Select-String -Pattern 'InputType\.NUMBER_DECIMAL'
  if ($decimalMatches.Count -lt 7) {
    Add-Failure "Expected at least 7 decimal amount inputs, found $($decimalMatches.Count)"
  }

  $numberMatches = $etsFiles | Select-String -Pattern 'InputType\.Number\b' -CaseSensitive
  foreach ($match in $numberMatches) {
    if ($match.Path -notmatch 'AccountManage\.ets$' -and $match.Path -notmatch 'CategoryManage\.ets$') {
      Add-Failure "Unexpected integer-only input outside sort fields: $($match.Path):$($match.LineNumber)"
    }
  }

  Assert-DecimalInput (Join-Path $Root 'entry/src/main/ets/components/AmountInput.ets') 'this.amountText'
  Assert-DecimalInput (Join-Path $Root 'entry/src/main/ets/pages/RecordEdit.ets') 'this.amountText'
  Assert-DecimalInput (Join-Path $Root 'entry/src/main/ets/pages/AccountManage.ets') 'this.balanceText'
  Assert-DecimalInput (Join-Path $Root 'entry/src/main/ets/pages/AccountManage.ets') 'this.initialText'
  Assert-DecimalInput (Join-Path $Root 'entry/src/main/ets/pages/BudgetSetting.ets') 'this.totalBudgetText'
  Assert-DecimalInput (Join-Path $Root 'entry/src/main/ets/pages/BudgetSetting.ets') 'item.budgetText'
  Assert-DecimalInput (Join-Path $Root 'entry/src/main/ets/pages/AutoBookkeeping.ets') 'this.editingAmountText'

  $deletedFiles = @(
    'entry/src/main/ets/extension/NotificationBookkeepingSubscriber.ets',
    'entry/src/main/ets/service/ReminderService.ets'
  )
  foreach ($file in $deletedFiles) {
    if (Test-Path (Join-Path $Root $file)) {
      Add-Failure "Release-disabled file still exists: $file"
    }
  }

  $diffCheck = & cmd /c 'git diff --check 2>&1'
  if ($LASTEXITCODE -ne 0) {
    Add-Failure "git diff --check failed:`n$diffCheck"
  }

  if ($failures.Count -gt 0) {
    Write-Output 'RELEASE CHECK FAILED'
    foreach ($failure in $failures) {
      Write-Output " - $failure"
    }
    exit 1
  }

  Write-Output 'RELEASE CHECK PASSED'
  Write-Output "Decimal amount inputs: $($decimalMatches.Count)"
  Write-Output "Integer-only inputs: $($numberMatches.Count) sort fields"
  Write-Output 'Permissions: empty'
  Write-Output 'Extensions: none'
  Write-Output 'Release feature flags: safe'
  Write-Output 'Routes/pages: consistent'
} finally {
  Pop-Location
}
