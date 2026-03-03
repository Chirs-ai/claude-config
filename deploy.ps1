#
# Claude Code 配置一键部署脚本 (PowerShell)
# 用法: powershell -ExecutionPolicy Bypass -File deploy.ps1
#
# 支持: Windows PowerShell 5.1+ / PowerShell Core 7+ (Windows/macOS/Linux)
#

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# ── 检测平台与 Claude 配置目录 ──
if ($IsLinux) {
    $Platform = "Linux"
    $ClaudeDir = Join-Path $env:HOME ".claude"
} elseif ($IsMacOS) {
    $Platform = "macOS"
    $ClaudeDir = Join-Path $env:HOME ".claude"
} else {
    $Platform = "Windows"
    $ClaudeDir = Join-Path $env:USERPROFILE ".claude"
}

Write-Host "=== Claude Code 配置部署 ===" -ForegroundColor Cyan
Write-Host "平台:   $Platform"
Write-Host "源目录: $ScriptDir"
Write-Host "目标:   $ClaudeDir"
Write-Host ""

# ── 创建目标目录 ──
if (-not (Test-Path $ClaudeDir)) {
    Write-Host "创建 $ClaudeDir ..."
    New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
}

# ── 部署单个文件 ──
function Deploy-File {
    param(
        [string]$Src,
        [string]$Dst,
        [string]$Label
    )

    if (Test-Path $Dst) {
        $srcHash = (Get-FileHash $Src -Algorithm MD5).Hash
        $dstHash = (Get-FileHash $Dst -Algorithm MD5).Hash
        if ($srcHash -eq $dstHash) {
            Write-Host "[=] $Label (无变化，跳过)" -ForegroundColor DarkGray
            return
        }
        Write-Host "[!] $Label 已存在，备份为 ${Label}.bak" -ForegroundColor Yellow
        Copy-Item $Dst "${Dst}.bak" -Force
    }
    Copy-Item $Src $Dst -Force
    Write-Host "[+] $Label" -ForegroundColor Green
}

# ── 部署配置文件 ──
Deploy-File (Join-Path $ScriptDir "CLAUDE.md") (Join-Path $ClaudeDir "CLAUDE.md") "CLAUDE.md"
Deploy-File (Join-Path $ScriptDir "settings.json") (Join-Path $ClaudeDir "settings.json") "settings.json"
Deploy-File (Join-Path $ScriptDir "statusline.sh") (Join-Path $ClaudeDir "statusline.sh") "statusline.sh"

# ── 部署 commands/ ──
$CmdDstDir = Join-Path $ClaudeDir "commands"
if (-not (Test-Path $CmdDstDir)) {
    New-Item -ItemType Directory -Path $CmdDstDir -Force | Out-Null
}

$CmdSrcDir = Join-Path $ScriptDir "commands"
Get-ChildItem -Path $CmdSrcDir -Filter "*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $dstFile = Join-Path $CmdDstDir $_.Name
    Deploy-File $_.FullName $dstFile "commands/$($_.Name)"
}

# ── 安装 ccstatusline ──
Write-Host ""
$npmPath = Get-Command npm -ErrorAction SilentlyContinue
if ($npmPath) {
    $installed = npm list -g ccstatusline 2>&1
    if ($installed -match "ccstatusline@") {
        $ver = ($installed | Select-String "ccstatusline@(.+)" | ForEach-Object { $_.Matches[0].Groups[1].Value }).Trim()
        Write-Host "[=] ccstatusline 已安装 (v$ver)" -ForegroundColor DarkGray
    } else {
        Write-Host "安装 ccstatusline ..."
        try {
            npm install -g ccstatusline 2>&1 | Out-Null
            Write-Host "[+] ccstatusline" -ForegroundColor Green
        } catch {
            Write-Host "[!] ccstatusline 安装失败，settings.json 中的 npx 会在首次使用时自动下载" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "[!] 未检测到 npm，跳过 ccstatusline 安装" -ForegroundColor Yellow
    Write-Host "    请先安装 Node.js，或后续通过 npx 自动下载"
}

Write-Host ""
Write-Host "=== 部署完成 ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "已部署的配置:"
Write-Host "  CLAUDE.md        - 全局指令 (Git commit 规范、Devlog 开发日志规范)"
Write-Host "  settings.json    - 状态栏、权限设置"
Write-Host "  statusline.sh    - 自定义状态栏脚本 (备用)"
Write-Host "  commands/        - 自定义命令 (gitpush 等)"
Write-Host "  ccstatusline     - npm 状态栏工具"
