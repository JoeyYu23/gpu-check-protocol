#Requires -Version 5.0
<#
.SYNOPSIS
    Run FurMark GPU stress test.
    运行 FurMark GPU 压力测试

.DESCRIPTION
    Launches FurMark with command-line parameters for stress test.
    Waits for configured duration, then terminates FurMark.
    Takes screenshots before and after.

.OUTPUTS
    String: "PASSED", "SKIPPED", "FAILED", or "ERROR"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$RepoRoot,
    [Parameter(Mandatory=$true)]
    [string]$OutputDir,
    [int]$DurationSec = 300
)

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $color = switch ($Level) { "OK" { "Green" } "WARN" { "Yellow" } "ERROR" { "Red" } default { "Cyan" } }
    Write-Host "[$ts][$Level] $Message" -ForegroundColor $color
}

$FurMarkPath = Join-Path $RepoRoot "tools\FurMark\FurMark.exe"
$LogPath     = Join-Path $OutputDir "furmark_log.txt"
$ScreenshotScript = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "capture_screenshot.ps1"

if (-not (Test-Path $FurMarkPath)) {
    Write-Log "FurMark 未找到: $FurMarkPath" "WARN"
    Write-Log "请从 https://geeks3d.com/furmark/ 下载并安装到 tools\FurMark\" "WARN"
    "[SKIP] FurMark not found at $FurMarkPath" | Out-File $LogPath -Encoding UTF8
    return "SKIPPED"
}

# FurMark command-line parameters:
#   /nogui          - start stress test immediately
#   /width=1920     - render resolution width
#   /height=1080    - render resolution height
#   /msaa=0         - anti-aliasing level
#   /log            - enable logging
#   /log_filename   - log file path
# Note: /msaa=8 is more demanding; /msaa=0 for basic stability
$FurMarkArgs = @(
    "/nogui",
    "/width=1920",
    "/height=1080",
    "/msaa=0",
    "/log",
    "/log_filename=`"$LogPath`""
)

Write-Log "FurMark 路径: $FurMarkPath" "INFO"
Write-Log "测试时长: $DurationSec 秒 ($([math]::Round($DurationSec/60,1)) 分钟)" "INFO"
Write-Log "启动 FurMark 压力测试，请不要移动鼠标或操作键盘..." "INFO"
Write-Host ""
Write-Host "  注意: FurMark 将在 $DurationSec 秒后自动关闭" -ForegroundColor Yellow
Write-Host ""

$StartTime = Get-Date

# Screenshot before FurMark
if (Test-Path $ScreenshotScript) {
    try { & $ScreenshotScript -OutputDir $OutputDir -Label "furmark_before" } catch {}
}

$Process = $null
$ExitCode = -1
$TestPassed = $false

try {
    $Process = Start-Process -FilePath $FurMarkPath -ArgumentList $FurMarkArgs -PassThru -ErrorAction Stop
    Write-Log "FurMark 已启动 (PID: $($Process.Id))" "OK"

    # Wait for configured duration with progress updates
    $EndTime = $StartTime.AddSeconds($DurationSec)
    $LastProgress = 0

    while ((Get-Date) -lt $EndTime) {
        Start-Sleep -Seconds 10

        # Check if FurMark crashed/exited early
        if ($Process.HasExited) {
            Write-Log "FurMark 提前退出 (退出码: $($Process.ExitCode))" "WARN"
            $ExitCode = $Process.ExitCode
            break
        }

        $Elapsed   = [int]((Get-Date) - $StartTime).TotalSeconds
        $Remaining = [int]($DurationSec - $Elapsed)
        $Progress  = [int](($Elapsed / $DurationSec) * 100)

        if ($Progress -ne $LastProgress -and $Progress % 20 -eq 0) {
            Write-Log "测试进行中... $Progress% 完成，剩余 $Remaining 秒" "INFO"
            # Periodic screenshot every 25%
            if (Test-Path $ScreenshotScript) {
                try { & $ScreenshotScript -OutputDir $OutputDir -Label "furmark_${Progress}pct" } catch {}
            }
            $LastProgress = $Progress
        }
    }

    if (-not $Process.HasExited) {
        Write-Log "测试时间到，正在关闭 FurMark..." "INFO"
        try {
            $Process.CloseMainWindow() | Out-Null
            Start-Sleep -Seconds 3
            if (-not $Process.HasExited) {
                $Process.Kill()
                Write-Log "FurMark 已强制关闭" "WARN"
            }
        } catch {
            Write-Log "关闭 FurMark 时出现非致命错误: $_" "WARN"
        }
        $ExitCode = 0
        $TestPassed = $true
    }

} catch {
    Write-Log "FurMark 启动失败: $_" "ERROR"
    $LogContent = "FurMark launch error: $_`nTime: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $LogContent | Out-File $LogPath -Encoding UTF8
    return "ERROR"
}

$EndActual = Get-Date
$ActualDuration = [int]($EndActual - $StartTime).TotalSeconds

# Screenshot after FurMark
if (Test-Path $ScreenshotScript) {
    try { & $ScreenshotScript -OutputDir $OutputDir -Label "furmark_after" } catch {}
}

# Write log summary
$LogSummary = @"
FurMark 压力测试日志
===================
开始时间:   $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))
结束时间:   $($EndActual.ToString('yyyy-MM-dd HH:mm:ss'))
计划时长:   $DurationSec 秒
实际时长:   $ActualDuration 秒
退出代码:   $ExitCode
FurMark路径: $FurMarkPath
测试结果:   $(if ($TestPassed) { '通过 (全程稳定运行)' } else { '异常 (提前退出)' })
"@
$LogSummary | Out-File $LogPath -Encoding UTF8 -Append

if ($TestPassed) {
    Write-Log "FurMark 测试完成，全程稳定运行 $ActualDuration 秒" "OK"
    return "PASSED"
} else {
    Write-Log "FurMark 提前退出，可能存在稳定性问题" "WARN"
    return "FAILED"
}
