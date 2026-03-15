#Requires -Version 5.0
<#
.SYNOPSIS
    Start and stop HWiNFO64 sensor logging.
    启动和停止 HWiNFO64 传感器 CSV 记录

.DESCRIPTION
    Provides two functions:
    - Start-HWiNFOLogging: launches HWiNFO64 in sensors-only mode with CSV logging
    - Stop-HWiNFOLogging:  stops HWiNFO64 and any CSV export process

    HWiNFO64 writes sensor data (GPU temp, fan speed, power, clock) to CSV.
    This file can be analyzed after the test to verify thermal behavior.

    Usage (dot-source from parent script):
        . scripts\run_hwinfo_logging.ps1
        Start-HWiNFOLogging -RepoRoot $RepoRoot -OutputDir $OutputDir
        # ... run tests ...
        Stop-HWiNFOLogging
#>

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

$script:HWiNFOProcess = $null
$script:HWiNFOCsvPath = $null

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $color = switch ($Level) { "OK" { "Green" } "WARN" { "Yellow" } "ERROR" { "Red" } default { "Cyan" } }
    Write-Host "[$ts][$Level] $Message" -ForegroundColor $color
}

function Start-HWiNFOLogging {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RepoRoot,
        [Parameter(Mandatory=$true)]
        [string]$OutputDir
    )

    $HWInfoExe = Join-Path $RepoRoot "tools\HWiNFO64.exe"

    if (-not (Test-Path $HWInfoExe)) {
        Write-Log "HWiNFO64.exe 未找到: $HWInfoExe" "WARN"
        Write-Log "跳过传感器记录功能" "WARN"
        return
    }

    $script:HWiNFOCsvPath = Join-Path $OutputDir "hwinfo_sensors.csv"

    # HWiNFO64 command-line options:
    #   -t          : start in tray (minimized)
    #   -s          : sensors-only (no main window, saves memory)
    # CSV logging is configured via HWiNFO64.ini or UI.
    # Since portable mode may not have pre-configured CSV settings,
    # we set registry key to enable CSV logging automatically.

    # Write HWiNFO64 registry settings for CSV logging
    try {
        $RegBase = "HKCU:\Software\HWiNFO64"
        if (-not (Test-Path $RegBase)) {
            New-Item -Path $RegBase -Force | Out-Null
        }
        # Enable sensor logging to CSV
        Set-ItemProperty -Path $RegBase -Name "SensorsCSVLogging" -Value 1 -Type DWord -ErrorAction Stop
        Set-ItemProperty -Path $RegBase -Name "SensorsCSVPath"    -Value $script:HWiNFOCsvPath -Type String -ErrorAction Stop
        Set-ItemProperty -Path $RegBase -Name "SensorsCSVPeriod"  -Value 1000 -Type DWord -ErrorAction Stop  # 1 second interval
        Write-Log "HWiNFO64 CSV 记录配置已写入注册表" "OK"
    } catch {
        Write-Log "HWiNFO64 注册表配置失败 (CSV可能不自动启动): $_" "WARN"
    }

    # Launch HWiNFO64 sensors-only mode
    $Args = @("-t", "-s")

    try {
        $script:HWiNFOProcess = Start-Process -FilePath $HWInfoExe -ArgumentList $Args -PassThru -WindowStyle Minimized -ErrorAction Stop
        Write-Log "HWiNFO64 已启动 (PID: $($script:HWiNFOProcess.Id))" "OK"
        Write-Log "CSV 输出: $script:HWiNFOCsvPath" "INFO"
        Write-Log "等待 HWiNFO64 初始化..." "INFO"
        Start-Sleep -Seconds 8
        Write-Log "HWiNFO64 传感器记录已就绪" "OK"
    } catch {
        Write-Log "HWiNFO64 启动失败: $_" "ERROR"
        $script:HWiNFOProcess = $null
    }
}

function Stop-HWiNFOLogging {
    if ($null -eq $script:HWiNFOProcess) {
        Write-Log "HWiNFO64 未在运行，跳过停止" "WARN"
        return
    }

    try {
        if (-not $script:HWiNFOProcess.HasExited) {
            $script:HWiNFOProcess.CloseMainWindow() | Out-Null
            Start-Sleep -Seconds 2
            if (-not $script:HWiNFOProcess.HasExited) {
                $script:HWiNFOProcess.Kill()
                Write-Log "HWiNFO64 已强制关闭" "WARN"
            } else {
                Write-Log "HWiNFO64 已正常关闭" "OK"
            }
        } else {
            Write-Log "HWiNFO64 已经退出" "INFO"
        }
    } catch {
        Write-Log "停止 HWiNFO64 时出现错误: $_" "WARN"
    }

    # Also kill any lingering HWiNFO64 processes by name
    try {
        $remaining = Get-Process -Name "HWiNFO64" -ErrorAction SilentlyContinue
        if ($remaining) {
            $remaining | Stop-Process -Force -ErrorAction SilentlyContinue
            Write-Log "已清理残留 HWiNFO64 进程" "INFO"
        }
    } catch {}

    if ($script:HWiNFOCsvPath -and (Test-Path $script:HWiNFOCsvPath)) {
        $Size = (Get-Item $script:HWiNFOCsvPath).Length
        Write-Log "HWiNFO64 CSV 记录大小: $([math]::Round($Size/1KB, 1)) KB" "OK"
    } else {
        Write-Log "HWiNFO64 CSV 文件未生成 (可能需要在 UI 中手动开启 CSV 导出)" "WARN"
    }

    $script:HWiNFOProcess = $null
}
