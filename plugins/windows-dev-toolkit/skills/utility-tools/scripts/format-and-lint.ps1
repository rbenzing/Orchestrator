<#
.SYNOPSIS
    Auto-format and lint source files before a Code Review agent is invoked.
.DESCRIPTION
    Runs prettier, eslint --fix, dotnet format, or equivalent tools to clean up
    whitespace and obvious syntax errors. Prevents wasting AI tokens on trivial
    style violations. Detects the project type automatically from config files.
.PARAMETER Root
    Repository root. Defaults to current directory.
.PARAMETER Fix
    Apply auto-fixes (default). Pass -Fix:$false to report-only (dry run).
.PARAMETER Paths
    Specific files or directories to lint. Defaults to the whole project.
.EXAMPLE
    .claude\skills\utility-tools\scripts\format-and-lint.ps1
.EXAMPLE
    .claude\skills\utility-tools\scripts\format-and-lint.ps1 -Fix:$false
.EXAMPLE
    .claude\skills\utility-tools\scripts\format-and-lint.ps1 -Paths "src/auth","src/api"
#>
[CmdletBinding()]
param(
    [string]$Root = (Get-Location).Path,
    [bool]$Fix = $true,
    [string[]]$Paths = @()
)
$ErrorActionPreference = "SilentlyContinue"

$pathArg = if ($Paths.Count -gt 0) { $Paths -join " " } else { "." }

Write-Host ""
Write-Host "  [format-and-lint] Detecting project type..." -ForegroundColor Yellow

$results = @()

# --- Node.js / TypeScript / JavaScript ---
$pkgJson = Join-Path $Root "package.json"
if (Test-Path $pkgJson) {
    # Prettier
    $prettierCfg = @(".prettierrc", ".prettierrc.json", ".prettierrc.yaml", "prettier.config.js") |
        Where-Object { Test-Path (Join-Path $Root $_) } | Select-Object -First 1
    if ($prettierCfg) {
        Write-Host "  [prettier] Running on $pathArg..." -ForegroundColor Cyan
        if ($Fix) {
            $out = & npx prettier --write $pathArg 2>&1
        } else {
            $out = & npx prettier --check $pathArg 2>&1
        }
        $results += [PSCustomObject]@{ Tool="prettier"; ExitCode=$LASTEXITCODE; Output=$out }
        Write-Host "    Exit: $LASTEXITCODE" -ForegroundColor $(if ($LASTEXITCODE -eq 0) { "Green" } else { "Yellow" })
    }

    # ESLint
    $eslintCfg = @(".eslintrc", ".eslintrc.json", ".eslintrc.js", ".eslintrc.cjs", "eslint.config.js") |
        Where-Object { Test-Path (Join-Path $Root $_) } | Select-Object -First 1
    if ($eslintCfg) {
        Write-Host "  [eslint] Running on $pathArg..." -ForegroundColor Cyan
        $eslintArgs = @($pathArg, "--ext", ".ts,.tsx,.js,.jsx")
        if ($Fix) { $eslintArgs += "--fix" }
        $out = & npx eslint @eslintArgs 2>&1
        $results += [PSCustomObject]@{ Tool="eslint"; ExitCode=$LASTEXITCODE; Output=$out }
        Write-Host "    Exit: $LASTEXITCODE" -ForegroundColor $(if ($LASTEXITCODE -eq 0) { "Green" } else { "Yellow" })
    }
}

# --- .NET ---
$csprojFiles = Get-ChildItem $Root -Filter "*.csproj" -Recurse -Depth 3 -ErrorAction SilentlyContinue
if ($csprojFiles) {
    Write-Host "  [dotnet format] Running..." -ForegroundColor Cyan
    $fmtArgs = @("format")
    if (-not $Fix) { $fmtArgs += "--verify-no-changes" }
    $out = & dotnet @fmtArgs 2>&1
    $results += [PSCustomObject]@{ Tool="dotnet-format"; ExitCode=$LASTEXITCODE; Output=$out }
    Write-Host "    Exit: $LASTEXITCODE" -ForegroundColor $(if ($LASTEXITCODE -eq 0) { "Green" } else { "Yellow" })
}

# --- Python ---
$pyFiles = Get-ChildItem $Root -Filter "pyproject.toml" -Recurse -Depth 2 -ErrorAction SilentlyContinue
if (-not $pyFiles) { $pyFiles = Get-ChildItem $Root -Filter "setup.py" -Recurse -Depth 2 -ErrorAction SilentlyContinue }
if ($pyFiles) {
    # ruff (fast) preferred; fall back to black
    & where.exe ruff 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [ruff] Running on $pathArg..." -ForegroundColor Cyan
        $ruffArgs = @("check", $pathArg)
        if ($Fix) { $ruffArgs += "--fix" }
        $out = & ruff @ruffArgs 2>&1
        $results += [PSCustomObject]@{ Tool="ruff"; ExitCode=$LASTEXITCODE; Output=$out }
        Write-Host "    Exit: $LASTEXITCODE" -ForegroundColor $(if ($LASTEXITCODE -eq 0) { "Green" } else { "Yellow" })
    } else {
        & where.exe black 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [black] Running on $pathArg..." -ForegroundColor Cyan
            $blackArgs = if ($Fix) { @($pathArg) } else { @("--check", $pathArg) }
            $out = & black @blackArgs 2>&1
            $results += [PSCustomObject]@{ Tool="black"; ExitCode=$LASTEXITCODE; Output=$out }
            Write-Host "    Exit: $LASTEXITCODE" -ForegroundColor $(if ($LASTEXITCODE -eq 0) { "Green" } else { "Yellow" })
        }
    }
}

# --- Summary ---
Write-Host ""
if ($results.Count -eq 0) {
    Write-Host "  [!] No supported formatter/linter config detected. Skipping." -ForegroundColor DarkGray
    Write-Host "      Supported: prettier, eslint, dotnet format, ruff, black" -ForegroundColor DarkGray
} else {
    $failed = $results | Where-Object { $_.ExitCode -ne 0 }
    if ($failed.Count -eq 0) {
        Write-Host "  [format-and-lint] All tools passed. $($results.Count) tool(s) ran." -ForegroundColor Green
    } else {
        Write-Host "  [format-and-lint] $($failed.Count) tool(s) reported issues:" -ForegroundColor Yellow
        foreach ($f in $failed) {
            Write-Host "    - $($f.Tool) (exit $($f.ExitCode))" -ForegroundColor Yellow
        }
        Write-Host "  Resolve lint errors before invoking the Code Reviewer agent." -ForegroundColor Yellow
    }
}
Write-Host ""

$worstExit = ($results | Measure-Object -Property ExitCode -Maximum).Maximum
exit $(if ($worstExit -gt 0) { 1 } else { 0 })

