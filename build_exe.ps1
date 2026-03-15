#Requires -Version 5.0
<#
.SYNOPSIS
    将 GUI 启动器打包成单个 EXE 文件

.DESCRIPTION
    使用 ps2exe 模块将 scripts/gui_launcher.ps1 编译为独立的 Windows EXE。
    用户只需双击 EXE，无需安装 PowerShell 环境或了解命令行。

.NOTES
    首次运行需要联网安装 ps2exe 模块（Install-Module）。
    编译完成后 EXE 可离线分发，目标机器无需 ps2exe。
    目标机器仍需 .NET Framework 4.5+（Windows 10/11 自带）。

HOW TO RUN:
    Right-click build_exe.ps1 -> "Run with PowerShell"
    or:
    powershell -ExecutionPolicy Bypass -File build_exe.ps1
#>

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$InputFile   = Join-Path $ScriptDir "scripts\gui_launcher.ps1"
$OutputFile  = Join-Path $ScriptDir "PC验机工具.exe"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  PC 验机工具 - EXE 打包脚本" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------------
# Step 1: Check / install ps2exe
# ---------------------------------------------------------------------------
Write-Host "[1/3] 检查 ps2exe 模块..." -ForegroundColor Yellow

$ps2exeInstalled = $false
try {
    $mod = Get-Module -ListAvailable -Name ps2exe -ErrorAction SilentlyContinue
    if ($mod) {
        $ps2exeInstalled = $true
        Write-Host "      ps2exe 已安装 (版本: $($mod.Version))" -ForegroundColor Green
    }
} catch {}

if (-not $ps2exeInstalled) {
    Write-Host "      ps2exe 未安装，正在从 PSGallery 安装..." -ForegroundColor Yellow
    Write-Host "      (需要联网，约需 30 秒)" -ForegroundColor Gray
    try {
        Install-Module -Name ps2exe -Scope CurrentUser -Force -AllowClobber
        Write-Host "      ps2exe 安装完成" -ForegroundColor Green
    } catch {
        Write-Host ""
        Write-Host "[ERROR] 安装 ps2exe 失败: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "手动安装方法:" -ForegroundColor Yellow
        Write-Host "  1. 以管理员身份运行 PowerShell" -ForegroundColor White
        Write-Host "  2. 执行: Install-Module -Name ps2exe -Force" -ForegroundColor White
        Write-Host "  3. 重新运行本脚本" -ForegroundColor White
        Write-Host ""
        Write-Host "或使用 winget 安装:" -ForegroundColor Yellow
        Write-Host "  winget install ps2exe" -ForegroundColor White
        Write-Host ""
        Read-Host "按 Enter 退出"
        exit 1
    }
}

# ---------------------------------------------------------------------------
# Step 2: Verify input file
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "[2/3] 检查源文件..." -ForegroundColor Yellow

if (-not (Test-Path $InputFile)) {
    Write-Host "[ERROR] 找不到源文件: $InputFile" -ForegroundColor Red
    Write-Host "        请确认在项目根目录运行本脚本" -ForegroundColor Gray
    Read-Host "按 Enter 退出"
    exit 1
}
Write-Host "      源文件: $InputFile" -ForegroundColor Green

# ---------------------------------------------------------------------------
# Step 3: Compile
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "[3/3] 正在编译..." -ForegroundColor Yellow

try {
    Invoke-ps2exe `
        -InputFile   $InputFile `
        -OutputFile  $OutputFile `
        -Title       "PC Check Protocol" `
        -Description "二手电脑验机工具 - PC Check Protocol v2.0" `
        -Company     "pc-check-protocol" `
        -Version     "2.0.0.0" `
        -noConsole `
        -requireAdmin `
        -Verbose

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "  打包完成！" -ForegroundColor Green
    Write-Host "  输出文件: $OutputFile" -ForegroundColor White
    Write-Host ""
    Write-Host "  使用方式：双击 PC验机工具.exe（推荐以管理员身份运行）" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "[ERROR] 编译失败: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "常见原因：" -ForegroundColor Yellow
    Write-Host "  - GUI 脚本中有语法错误（运行前先测试 gui_launcher.ps1）" -ForegroundColor White
    Write-Host "  - ps2exe 版本过旧（尝试: Update-Module ps2exe）" -ForegroundColor White
    Write-Host "  - 需要管理员权限（右键以管理员身份运行）" -ForegroundColor White
}

Write-Host ""
Read-Host "按 Enter 退出"
