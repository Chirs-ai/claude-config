#
# Claude Code / Codex local config installer (PowerShell)
# Usage: powershell -ExecutionPolicy Bypass -File deploy.ps1
#
# Supports: Windows PowerShell 5.1+ / PowerShell 7+
#

param(
    [switch]$CodexOnly
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

if ($IsLinux) {
    $Platform = "Linux"
    $HomeDir = $env:HOME
} elseif ($IsMacOS) {
    $Platform = "macOS"
    $HomeDir = $env:HOME
} else {
    $Platform = "Windows"
    $HomeDir = $env:USERPROFILE
}

$ClaudeDir = Join-Path $HomeDir ".claude"
$CodexDir = Join-Path $HomeDir ".codex"

Write-Host "=== Claude Code / Codex config deploy ===" -ForegroundColor Cyan
Write-Host "Platform:      $Platform"
Write-Host "Source:        $ScriptDir"
Write-Host "Codex target:  $CodexDir"
if (-not $CodexOnly) {
    Write-Host "Claude target: $ClaudeDir"
}
Write-Host ""

function Ensure-Dir {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Deploy-File {
    param(
        [string]$Src,
        [string]$Dst,
        [string]$Label
    )

    if (-not (Test-Path $Src)) {
        Write-Host "[!] Missing source: $Src" -ForegroundColor Yellow
        return
    }

    Ensure-Dir (Split-Path -Parent $Dst)

    if (Test-Path $Dst) {
        $srcHash = (Get-FileHash $Src -Algorithm MD5).Hash
        $dstHash = (Get-FileHash $Dst -Algorithm MD5).Hash
        if ($srcHash -eq $dstHash) {
            Write-Host "[=] $Label (unchanged)" -ForegroundColor DarkGray
            return
        }

        Copy-Item $Dst "${Dst}.bak" -Force
        Write-Host "[!] $Label exists; backed up to ${Dst}.bak" -ForegroundColor Yellow
    }

    Copy-Item $Src $Dst -Force
    Write-Host "[+] $Label" -ForegroundColor Green
}

function Invoke-CodexMarketplaceRegistration {
    param([string]$MarketplaceRoot)

    $codexPath = Get-Command codex -ErrorAction SilentlyContinue
    if (-not $codexPath) {
        Write-Host "[!] codex CLI not found; skipped marketplace registration" -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "Registering Codex local marketplace ..."

    $addOutput = & codex plugin marketplace add $MarketplaceRoot 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[+] Codex marketplace: claude-config" -ForegroundColor Green
        return
    }

    $upgradeOutput = & codex plugin marketplace upgrade claude-config 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[=] Codex marketplace: claude-config already registered; upgraded" -ForegroundColor DarkGray
        return
    }

    Write-Host "[!] Codex marketplace registration failed" -ForegroundColor Yellow
    if ($addOutput) {
        Write-Host "    add output: $($addOutput -join ' ')"
    }
    if ($upgradeOutput) {
        Write-Host "    upgrade output: $($upgradeOutput -join ' ')"
    }
}

function Enable-CodexPlugin {
    param(
        [string]$ConfigPath,
        [string]$PluginRef
    )

    Ensure-Dir (Split-Path -Parent $ConfigPath)
    if (-not (Test-Path $ConfigPath)) {
        New-Item -ItemType File -Path $ConfigPath -Force | Out-Null
    }

    $section = "[plugins.`"$PluginRef`"]"
    $config = Get-Content -Raw -Encoding UTF8 $ConfigPath
    if ($null -eq $config) {
        $config = ""
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)

    if ($config -notmatch [regex]::Escape($section)) {
        if ($config.Length -gt 0 -and -not $config.EndsWith("`r`n") -and -not $config.EndsWith("`n")) {
            $config += "`r`n"
        }
        $config += "`r`n$section`r`nenabled = true`r`n"
        [System.IO.File]::WriteAllText($ConfigPath, $config, $utf8NoBom)
        Write-Host "[+] Codex plugin enabled: $PluginRef" -ForegroundColor Green
        return
    }

    $pattern = "(?ms)(^\[plugins\.`"$([regex]::Escape($PluginRef))`"\]\s*)(.*?)(?=^\[|\z)"
    if ($config -notmatch $pattern) {
        Write-Host "[!] Could not update Codex plugin section: $PluginRef" -ForegroundColor Yellow
        return
    }

    $body = $Matches[2]
    if ($body -match "(?m)^\s*enabled\s*=") {
        $body = [regex]::Replace($body, "(?m)^\s*enabled\s*=.*$", "enabled = true", 1)
    } else {
        $body = "enabled = true`r`n$body"
    }
    $config = [regex]::Replace($config, $pattern, "`${1}$body", 1)
    [System.IO.File]::WriteAllText($ConfigPath, $config, $utf8NoBom)

    Write-Host "[=] Codex plugin enabled: $PluginRef" -ForegroundColor DarkGray
}

function Sync-CodexPluginCache {
    param(
        [string]$PluginSource,
        [string]$CodexHome,
        [string]$MarketplaceName,
        [string]$PluginName
    )

    if (-not (Test-Path $PluginSource)) {
        Write-Host "[!] Missing Codex plugin source: $PluginSource" -ForegroundColor Yellow
        return
    }

    $cacheRoot = Join-Path $CodexHome "plugins\cache\$MarketplaceName"
    $cachePath = Join-Path $cacheRoot $PluginName
    Ensure-Dir $cacheRoot

    $resolvedCodexHome = [System.IO.Path]::GetFullPath($CodexHome)
    $resolvedCachePath = [System.IO.Path]::GetFullPath($cachePath)
    if (-not $resolvedCachePath.StartsWith($resolvedCodexHome, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to update plugin cache outside Codex home: $resolvedCachePath"
    }

    if (Test-Path $cachePath) {
        Remove-Item -LiteralPath $cachePath -Recurse -Force
    }

    Copy-Item -LiteralPath $PluginSource -Destination $cachePath -Recurse -Force
    Write-Host "[+] Codex plugin cache: $MarketplaceName/$PluginName" -ForegroundColor Green
}

function Sync-CodexSkills {
    param(
        [string]$SkillsSource,
        [string]$CommandsSource,
        [string]$CodexHome
    )

    $skillsTarget = Join-Path $CodexHome "skills"
    $commandsTarget = Join-Path $CodexHome "commands"
    Ensure-Dir $skillsTarget
    Ensure-Dir $commandsTarget

    Get-ChildItem -Path $CommandsSource -Filter "*.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
        Deploy-File $_.FullName (Join-Path $commandsTarget $_.Name) "codex/commands/$($_.Name)"
    }

    Get-ChildItem -Path $SkillsSource -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $target = Join-Path $skillsTarget $_.Name
        if (Test-Path $target) {
            Remove-Item -LiteralPath $target -Recurse -Force
        }
        Copy-Item -LiteralPath $_.FullName -Destination $target -Recurse -Force
        Write-Host "[+] Codex skill: $($_.Name)" -ForegroundColor Green
    }
}

if (-not $CodexOnly) {
    $missing = @()
    if (-not (Get-Command jq -ErrorAction SilentlyContinue)) { $missing += "jq" }
    if (-not (Get-Command bc -ErrorAction SilentlyContinue)) { $missing += "bc" }

    if ($missing.Count -eq 0) {
        Write-Host "[=] Optional shell statusline dependencies found (jq, bc)" -ForegroundColor DarkGray
    } else {
        Write-Host "[!] Optional shell statusline dependencies missing: $($missing -join ', ')" -ForegroundColor Yellow
        if ($Platform -eq "Windows") {
            Write-Host "    This is OK if you use ccstatusline. Install via winget/scoop/chocolatey only if you need statusline.sh."
        }
    }
    Write-Host ""
}

Ensure-Dir $CodexDir

$TplSrcDir = Join-Path $ScriptDir "templates"

if (-not $CodexOnly) {
    Ensure-Dir $ClaudeDir

    Deploy-File (Join-Path $ScriptDir "CLAUDE.md") (Join-Path $ClaudeDir "CLAUDE.md") "CLAUDE.md"
    Deploy-File (Join-Path $ScriptDir "settings.json") (Join-Path $ClaudeDir "settings.json") "settings.json"
    Deploy-File (Join-Path $ScriptDir "statusline.sh") (Join-Path $ClaudeDir "statusline.sh") "statusline.sh"

    $CmdSrcDir = Join-Path $ScriptDir "commands"
    $CmdDstDir = Join-Path $ClaudeDir "commands"
    Ensure-Dir $CmdDstDir
    Get-ChildItem -Path $CmdSrcDir -Filter "*.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
        Deploy-File $_.FullName (Join-Path $CmdDstDir $_.Name) "commands/$($_.Name)"
    }

    $TplDstDir = Join-Path $ClaudeDir "templates"
    Ensure-Dir $TplDstDir
    Get-ChildItem -Path $TplSrcDir -File -ErrorAction SilentlyContinue | ForEach-Object {
        Deploy-File $_.FullName (Join-Path $TplDstDir $_.Name) "templates/$($_.Name)"
    }
}

$CodexTplDir = Join-Path $CodexDir "templates"
Ensure-Dir $CodexTplDir
Get-ChildItem -Path $TplSrcDir -File -ErrorAction SilentlyContinue | ForEach-Object {
    Deploy-File $_.FullName (Join-Path $CodexTplDir $_.Name) "codex/templates/$($_.Name)"
}

$CodexPromptSrcDir = Join-Path $ScriptDir "codex\prompts"
$CodexPromptsDir = Join-Path $CodexDir "prompts"
Ensure-Dir $CodexPromptsDir
Get-ChildItem -Path $CodexPromptSrcDir -Filter "*.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
    Deploy-File $_.FullName (Join-Path $CodexPromptsDir $_.Name) "codex/prompts/$($_.Name)"
}

$CodexPluginDir = Join-Path $ScriptDir "codex\plugins\claude-config-commands"
Sync-CodexSkills `
    (Join-Path $CodexPluginDir "skills") `
    (Join-Path $CodexPluginDir "commands") `
    $CodexDir

Invoke-CodexMarketplaceRegistration (Join-Path $ScriptDir "codex")
Sync-CodexPluginCache `
    $CodexPluginDir `
    $CodexDir `
    "claude-config" `
    "claude-config-commands"
Enable-CodexPlugin (Join-Path $CodexDir "config.toml") "claude-config-commands@claude-config"

if (-not $CodexOnly) {
    Write-Host ""
    $npmPath = Get-Command npm -ErrorAction SilentlyContinue
    if ($npmPath) {
        $installed = npm list -g ccstatusline 2>&1
        if ($installed -match "ccstatusline@") {
            $ver = ($installed | Select-String "ccstatusline@(.+)" | ForEach-Object { $_.Matches[0].Groups[1].Value } | Select-Object -First 1).Trim()
            Write-Host "[=] ccstatusline installed (v$ver)" -ForegroundColor DarkGray
        } else {
            Write-Host "Installing ccstatusline ..."
            try {
                npm install -g ccstatusline 2>&1 | Out-Null
                Write-Host "[+] ccstatusline" -ForegroundColor Green
            } catch {
                Write-Host "[!] ccstatusline install failed; settings.json can still use npx on first run" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "[!] npm not found; skipped ccstatusline install" -ForegroundColor Yellow
        Write-Host "    Install Node.js later if you want npm-managed ccstatusline."
    }
}

Write-Host ""
Write-Host "=== Deploy complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installed:"
if (-not $CodexOnly) {
    Write-Host "  CLAUDE.md              -> $ClaudeDir"
    Write-Host "  settings.json          -> $ClaudeDir"
    Write-Host "  statusline.sh          -> $ClaudeDir"
    Write-Host "  commands/*.md          -> $(Join-Path $ClaudeDir "commands")"
    Write-Host "  templates/*            -> $(Join-Path $ClaudeDir "templates")"
}
Write-Host "  codex/templates/*      -> $(Join-Path $CodexDir "templates")"
Write-Host "  codex/prompts/*.md     -> $(Join-Path $CodexDir "prompts")"
Write-Host "  codex/commands/*.md    -> $(Join-Path $CodexDir "commands")"
Write-Host "  codex/skills/*         -> $(Join-Path $CodexDir "skills")"
Write-Host "  codex plugin skills    -> `$gitpush, `$deploy, `$deploy-init, ..."
