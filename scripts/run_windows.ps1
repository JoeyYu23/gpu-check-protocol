#Requires -Version 5.0
<#
.SYNOPSIS
    GPU Check Protocol - Main Orchestrator
    二手显卡验机工具主脚本

.DESCRIPTION
    Orchestrates the entire GPU verification workflow:
    1. Create timestamped output directory
    2. Collect system information
    3. Check available tools
    4. Start HWiNFO sensor logging
    5. Run FurMark GPU stress test
    6. Run OCCT VRAM test
    7. Stop HWiNFO logging
    8. Package results into zip

    SAFETY: This script only reads hardware data and runs benchmarks.
    It does NOT access personal files, upload data, or modify system settings.

.NOTES
    Author: gpu-check-protocol
    Requires: PowerShell 5.0+, Windows 10/11
#>

param(
    [string]$ScriptRoot = $PSScriptRoot
)

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ---------------------------------------------------------------------------
# Bootstrap: resolve paths
# ---------------------------------------------------------------------------
if (-not $ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
$RepoRoot = Split-Path -Parent $ScriptRoot

# Load config
$ConfigPath = Join-Path $RepoRoot "config\benchmark_config.json"
if (-not (Test-Path $ConfigPath)) {
    Write-Host "[ERROR] Cannot find config\benchmark_config.json" -ForegroundColor Red
    exit 1
}
$Config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

# Create timestamped output directory
$Timestamp  = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputBase = Join-Path $RepoRoot $Config.output_dir
$OutputDir  = Join-Path $OutputBase $Timestamp

try {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
} catch {
    Write-Host "[ERROR] Cannot create output directory: $OutputDir" -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------------
# Start transcript
# ---------------------------------------------------------------------------
$TranscriptPath = Join-Path $OutputDir "session_transcript.log"
try {
    Start-Transcript -Path $TranscriptPath -Append | Out-Null
} catch {
    Write-Host "[WARN] Could not start transcript: $_" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $color = switch ($Level) {
        "INFO"    { "Cyan" }
        "OK"      { "Green" }
        "WARN"    { "Yellow" }
        "ERROR"   { "Red" }
        "STEP"    { "Magenta" }
        default   { "White" }
    }
    Write-Host "[$ts][$Level] $Message" -ForegroundColor $color
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor DarkCyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor DarkCyan
}

function Invoke-Script {
    param([string]$ScriptPath, [hashtable]$Params = @{})
    if (-not (Test-Path $ScriptPath)) {
        Write-Log "Script not found: $ScriptPath" "ERROR"
        return $false
    }
    try {
        & $ScriptPath @Params
        return $true
    } catch {
        Write-Log "Script failed [$ScriptPath]: $_" "ERROR"
        return $false
    }
}

# ---------------------------------------------------------------------------
# Check admin privileges
# ---------------------------------------------------------------------------
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $IsAdmin) {
    Write-Log "Not running as Administrator. Some hardware readings may be limited." "WARN"
    Write-Log "For best results, right-click run_windows.bat and choose 'Run as Administrator'" "WARN"
}

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor DarkCyan
Write-Host "   GPU 验机工具 (GPU Check Protocol) v1.0" -ForegroundColor Cyan
Write-Host "   二手显卡交易验机 - 安全开源 数据不离本机" -ForegroundColor Cyan
Write-Host "   Output: $OutputDir" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor DarkCyan
Write-Host ""

$SummaryLines = [System.Collections.Generic.List[string]]::new()
$SummaryLines.Add("GPU Check Protocol - 验机报告摘要")
$SummaryLines.Add("生成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$SummaryLines.Add("输出目录: $OutputDir")
$SummaryLines.Add("")

# ---------------------------------------------------------------------------
# Step 1: Collect system info
# ---------------------------------------------------------------------------
Write-Section "步骤 1/5 - 收集系统信息"
$CollectScript = Join-Path $ScriptRoot "collect_system_info.ps1"
try {
    & $CollectScript -OutputDir $OutputDir
    Write-Log "系统信息收集完成" "OK"
    $SummaryLines.Add("[OK] 系统信息 - 已收集 (system_info.txt)")
} catch {
    Write-Log "系统信息收集失败: $_" "ERROR"
    $SummaryLines.Add("[FAIL] 系统信息 - 收集失败")
}

# ---------------------------------------------------------------------------
# Step 2: Check tools
# ---------------------------------------------------------------------------
Write-Section "步骤 2/5 - 检查工具"
$CheckScript = Join-Path $ScriptRoot "check_tools.ps1"
$ToolStatus  = $null
try {
    $ToolStatus = & $CheckScript -RepoRoot $RepoRoot
    $SummaryLines.Add("")
    $SummaryLines.Add("工具检查结果:")
    foreach ($key in $ToolStatus.Keys) {
        $found = if ($ToolStatus[$key]) { "[找到]" } else { "[缺失]" }
        $SummaryLines.Add("  $found $key")
    }
} catch {
    Write-Log "工具检查失败: $_" "ERROR"
}

# ---------------------------------------------------------------------------
# Step 3: Screenshot before tests
# ---------------------------------------------------------------------------
if ($Config.screenshot_before_after) {
    Write-Section "截图 - 测试前"
    $ScreenshotScript = Join-Path $ScriptRoot "capture_screenshot.ps1"
    try {
        & $ScreenshotScript -OutputDir $OutputDir -Label "before_tests"
        Write-Log "测试前截图完成" "OK"
    } catch {
        Write-Log "截图失败 (非致命): $_" "WARN"
    }
}

# ---------------------------------------------------------------------------
# Step 4a: Start HWiNFO logging
# ---------------------------------------------------------------------------
Write-Section "步骤 3/5 - 启动 HWiNFO 传感器记录"
$HWInfoScript = Join-Path $ScriptRoot "run_hwinfo_logging.ps1"
$HWInfoStarted = $false
if ($ToolStatus -and $ToolStatus["HWiNFO64"]) {
    try {
        . $HWInfoScript   # dot-source to get functions
        Start-HWiNFOLogging -RepoRoot $RepoRoot -OutputDir $OutputDir
        $HWInfoStarted = $true
        Write-Log "HWiNFO 传感器记录已启动" "OK"
        $SummaryLines.Add("")
        $SummaryLines.Add("[OK] HWiNFO 传感器记录 - 已启动")
    } catch {
        Write-Log "HWiNFO 启动失败: $_" "WARN"
        $SummaryLines.Add("[SKIP] HWiNFO 传感器记录 - 启动失败")
    }
} else {
    Write-Log "HWiNFO64 不存在，跳过传感器记录" "WARN"
    $SummaryLines.Add("[SKIP] HWiNFO 传感器记录 - 工具未找到")
}

# Short wait for HWiNFO to initialize
if ($HWInfoStarted) { Start-Sleep -Seconds 5 }

# ---------------------------------------------------------------------------
# Step 4b: FurMark GPU stress test
# ---------------------------------------------------------------------------
Write-Section "步骤 4/5 - FurMark GPU 压力测试"
$FurMarkResult = "SKIP"
if ($Config.enable_furmark) {
    $FurMarkScript = Join-Path $ScriptRoot "run_furmark.ps1"
    try {
        $FurMarkResult = & $FurMarkScript -RepoRoot $RepoRoot -OutputDir $OutputDir -DurationSec $Config.furmark_duration_sec
        $SummaryLines.Add("")
        $SummaryLines.Add("[结果] FurMark: $FurMarkResult")
    } catch {
        Write-Log "FurMark 脚本异常: $_" "ERROR"
        $SummaryLines.Add("[FAIL] FurMark - 脚本异常")
    }
} else {
    Write-Log "FurMark 已在配置中禁用，跳过" "INFO"
    $SummaryLines.Add("[SKIP] FurMark - 配置已禁用")
}

# ---------------------------------------------------------------------------
# Step 4c: OCCT VRAM test
# ---------------------------------------------------------------------------
Write-Section "步骤 5/5 - OCCT VRAM 测试"
$OcctResult = "SKIP"
if ($Config.enable_occt) {
    $OcctScript = Join-Path $ScriptRoot "run_occt.ps1"
    try {
        $OcctResult = & $OcctScript -RepoRoot $RepoRoot -OutputDir $OutputDir -DurationSec $Config.occt_vram_duration_sec
        $SummaryLines.Add("[结果] OCCT VRAM: $OcctResult")
    } catch {
        Write-Log "OCCT 脚本异常: $_" "ERROR"
        $SummaryLines.Add("[FAIL] OCCT - 脚本异常")
    }
} else {
    Write-Log "OCCT 已在配置中禁用，跳过" "INFO"
    $SummaryLines.Add("[SKIP] OCCT - 配置已禁用")
}

# ---------------------------------------------------------------------------
# Stop HWiNFO logging
# ---------------------------------------------------------------------------
if ($HWInfoStarted) {
    Write-Log "停止 HWiNFO 传感器记录..." "INFO"
    try {
        Stop-HWiNFOLogging
        Write-Log "HWiNFO 记录已停止" "OK"
    } catch {
        Write-Log "停止 HWiNFO 失败 (非致命): $_" "WARN"
    }
}

# ---------------------------------------------------------------------------
# Screenshot after tests
# ---------------------------------------------------------------------------
if ($Config.screenshot_before_after) {
    Write-Section "截图 - 测试后"
    try {
        & $ScreenshotScript -OutputDir $OutputDir -Label "after_tests"
        Write-Log "测试后截图完成" "OK"
        $SummaryLines.Add("[OK] 截图 - 测试前后各一张")
    } catch {
        Write-Log "截图失败 (非致命): $_" "WARN"
    }
}

# ---------------------------------------------------------------------------
# Write summary
# ---------------------------------------------------------------------------
$SummaryLines.Add("")
$SummaryLines.Add("完成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$SummaryPath = Join-Path $OutputDir "test_summary.txt"
$SummaryLines | Out-File -FilePath $SummaryPath -Encoding UTF8

# ---------------------------------------------------------------------------
# Package results
# ---------------------------------------------------------------------------
if ($Config.zip_results) {
    Write-Section "打包结果"
    $PackageScript = Join-Path $ScriptRoot "package_results.ps1"
    try {
        & $PackageScript -OutputDir $OutputDir -Timestamp $Timestamp
    } catch {
        Write-Log "打包失败: $_" "ERROR"
    }
}

# ---------------------------------------------------------------------------
# Final message
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  验机完成！" -ForegroundColor Green
Write-Host "  结果目录: $OutputDir" -ForegroundColor White
if ($Config.zip_results) {
    $ZipPath = Join-Path $OutputBase "gpu_check_$Timestamp.zip"
    Write-Host "  压缩包:   $ZipPath" -ForegroundColor White
}
Write-Host "  请将上述文件发送给买家核验" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Green

try { Stop-Transcript | Out-Null } catch {}
