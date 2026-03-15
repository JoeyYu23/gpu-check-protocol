#Requires -Version 5.0
<#
.SYNOPSIS
    Collect system hardware information via WMI/CIM.
    收集系统硬件信息

.DESCRIPTION
    Reads CPU, GPU, RAM, motherboard, disk info using WMI.
    Writes to system_info.txt and summary.txt in OutputDir.
    No external tools required.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputDir
)

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $color = switch ($Level) { "OK" { "Green" } "WARN" { "Yellow" } "ERROR" { "Red" } default { "Cyan" } }
    Write-Host "[$ts][$Level] $Message" -ForegroundColor $color
}

function Safe-Get {
    param([scriptblock]$Block, [string]$Default = "N/A")
    try { $result = & $Block; if ($null -eq $result -or $result -eq '') { $Default } else { $result } }
    catch { $Default }
}

Write-Log "开始收集系统信息..." "INFO"

$Lines  = [System.Collections.Generic.List[string]]::new()
$Summary = [System.Collections.Generic.List[string]]::new()

$Lines.Add("GPU Check Protocol - 系统信息报告")
$Lines.Add("生成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$Lines.Add("=" * 60)
$Lines.Add("")

# ---------------------------------------------------------------------------
# Windows Version
# ---------------------------------------------------------------------------
$Lines.Add("[操作系统]")
try {
    $OS = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    $Lines.Add("  系统:       $($OS.Caption)")
    $Lines.Add("  版本:       $($OS.Version)")
    $Lines.Add("  构建号:     $($OS.BuildNumber)")
    $Lines.Add("  系统盘:     $($OS.SystemDirectory)")
    $Lines.Add("  语言:       $($OS.MUILanguages -join ', ')")
    $Summary.Add("OS: $($OS.Caption) Build $($OS.BuildNumber)")
    Write-Log "操作系统信息收集完成" "OK"
} catch {
    $Lines.Add("  [读取失败] $_")
    Write-Log "操作系统信息读取失败: $_" "WARN"
}
$Lines.Add("")

# ---------------------------------------------------------------------------
# CPU
# ---------------------------------------------------------------------------
$Lines.Add("[CPU 处理器]")
try {
    $CPUs = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop
    foreach ($CPU in $CPUs) {
        $Lines.Add("  型号:       $($CPU.Name.Trim())")
        $Lines.Add("  核心数:     $($CPU.NumberOfCores)")
        $Lines.Add("  线程数:     $($CPU.NumberOfLogicalProcessors)")
        $Lines.Add("  基础频率:   $($CPU.MaxClockSpeed) MHz")
        $Lines.Add("  当前频率:   $($CPU.CurrentClockSpeed) MHz")
        $Lines.Add("  架构:       $($CPU.Architecture)")
        $Lines.Add("  L2缓存:     $($CPU.L2CacheSize) KB")
        $Lines.Add("  L3缓存:     $($CPU.L3CacheSize) KB")
        $Summary.Add("CPU: $($CPU.Name.Trim()) ($($CPU.NumberOfCores)C/$($CPU.NumberOfLogicalProcessors)T)")
    }
    Write-Log "CPU 信息收集完成" "OK"
} catch {
    $Lines.Add("  [读取失败] $_")
    Write-Log "CPU 信息读取失败: $_" "WARN"
}
$Lines.Add("")

# ---------------------------------------------------------------------------
# Motherboard
# ---------------------------------------------------------------------------
$Lines.Add("[主板]")
try {
    $MB = Get-CimInstance -ClassName Win32_BaseBoard -ErrorAction Stop
    $Lines.Add("  制造商:     $($MB.Manufacturer)")
    $Lines.Add("  型号:       $($MB.Product)")
    $Lines.Add("  版本:       $($MB.Version)")
    $Lines.Add("  序列号:     $($MB.SerialNumber)")
    $Summary.Add("主板: $($MB.Manufacturer) $($MB.Product)")
    Write-Log "主板信息收集完成" "OK"
} catch {
    $Lines.Add("  [读取失败] $_")
    Write-Log "主板信息读取失败: $_" "WARN"
}
$Lines.Add("")

# BIOS version
$Lines.Add("[BIOS]")
try {
    $BIOS = Get-CimInstance -ClassName Win32_BIOS -ErrorAction Stop
    $Lines.Add("  制造商:     $($BIOS.Manufacturer)")
    $Lines.Add("  版本:       $($BIOS.SMBIOSBIOSVersion)")
    $Lines.Add("  发布日期:   $($BIOS.ReleaseDate)")
} catch {
    $Lines.Add("  [读取失败] $_")
}
$Lines.Add("")

# ---------------------------------------------------------------------------
# RAM
# ---------------------------------------------------------------------------
$Lines.Add("[内存 RAM]")
try {
    $RAMs = Get-CimInstance -ClassName Win32_PhysicalMemory -ErrorAction Stop
    $TotalGB = [math]::Round(($RAMs | Measure-Object -Property Capacity -Sum).Sum / 1GB, 1)
    $Lines.Add("  总容量:     $TotalGB GB")
    $Lines.Add("  条数:       $($RAMs.Count)")
    $i = 1
    foreach ($RAM in $RAMs) {
        $CapGB = [math]::Round($RAM.Capacity / 1GB, 1)
        $Lines.Add("  条 $i`:       $CapGB GB | $($RAM.Speed) MHz | $($RAM.MemoryType) | 插槽: $($RAM.DeviceLocator)")
        $i++
    }
    $Summary.Add("RAM: $TotalGB GB ($($RAMs.Count) x $([math]::Round($RAMs[0].Capacity/1GB,1))GB @ $($RAMs[0].Speed)MHz)")
    Write-Log "内存信息收集完成" "OK"
} catch {
    $Lines.Add("  [读取失败] $_")
    Write-Log "内存信息读取失败: $_" "WARN"
}
$Lines.Add("")

# ---------------------------------------------------------------------------
# GPU (Video Controller)
# ---------------------------------------------------------------------------
$Lines.Add("[显卡 GPU]")
try {
    $GPUs = Get-CimInstance -ClassName Win32_VideoController -ErrorAction Stop
    foreach ($GPU in $GPUs) {
        $VramMB = if ($GPU.AdapterRAM -gt 0) { [math]::Round($GPU.AdapterRAM / 1MB) } else { "N/A" }
        $VramGB = if ($GPU.AdapterRAM -gt 0) { [math]::Round($GPU.AdapterRAM / 1GB, 1) } else { "N/A" }
        $Lines.Add("  名称:       $($GPU.Name)")
        $Lines.Add("  显存 (WMI): $VramMB MB ($VramGB GB)")
        $Lines.Add("  驱动版本:   $($GPU.DriverVersion)")
        $Lines.Add("  驱动日期:   $($GPU.DriverDate)")
        $Lines.Add("  分辨率:     $($GPU.CurrentHorizontalResolution) x $($GPU.CurrentVerticalResolution)")
        $Lines.Add("  刷新率:     $($GPU.CurrentRefreshRate) Hz")
        $Lines.Add("  视频模式:   $($GPU.VideoModeDescription)")
        $Lines.Add("  PNP设备ID:  $($GPU.PNPDeviceID)")
        $Lines.Add("")
        $Summary.Add("GPU: $($GPU.Name) | VRAM: $VramGB GB | 驱动: $($GPU.DriverVersion)")
    }
    Write-Log "GPU 信息收集完成" "OK"
} catch {
    $Lines.Add("  [读取失败] $_")
    Write-Log "GPU 信息读取失败: $_" "WARN"
}

# Try to get more accurate VRAM via registry (NVIDIA)
$Lines.Add("[显卡补充信息 - 注册表]")
try {
    $NvRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Video"
    $NvKeys = Get-ChildItem $NvRegPath -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match "NVIDIA" } |
        Select-Object -First 5
    if ($NvKeys) {
        $Lines.Add("  检测到 NVIDIA 注册表项: $($NvKeys.Count) 个")
    } else {
        $Lines.Add("  未找到 NVIDIA 专属注册表项")
    }
} catch {
    $Lines.Add("  [注册表读取跳过]")
}
$Lines.Add("")

# DXDIAG equivalent - DirectX info
$Lines.Add("[DirectX / 显示适配器]")
try {
    $DXPath = "$env:SystemRoot\System32\dxdiag.exe"
    if (Test-Path $DXPath) {
        $DXFile = Join-Path $OutputDir "dxdiag_output.txt"
        $proc = Start-Process -FilePath $DXPath -ArgumentList "/t `"$DXFile`"" -PassThru -WindowStyle Hidden
        $proc.WaitForExit(30000) | Out-Null
        if (Test-Path $DXFile) {
            $Lines.Add("  DXDiag 报告已生成: dxdiag_output.txt")
            Write-Log "DXDiag 报告生成完成" "OK"
        }
    }
} catch {
    $Lines.Add("  [DXDiag 跳过] $_")
}
$Lines.Add("")

# ---------------------------------------------------------------------------
# Disk
# ---------------------------------------------------------------------------
$Lines.Add("[存储设备]")
try {
    $Disks = Get-CimInstance -ClassName Win32_DiskDrive -ErrorAction Stop
    foreach ($Disk in $Disks) {
        $SizeGB = [math]::Round($Disk.Size / 1GB, 1)
        $Lines.Add("  名称:       $($Disk.Caption)")
        $Lines.Add("  接口:       $($Disk.InterfaceType)")
        $Lines.Add("  容量:       $SizeGB GB")
        $Lines.Add("  序列号:     $($Disk.SerialNumber.Trim())")
        $Lines.Add("  固件:       $($Disk.FirmwareRevision.Trim())")
        $Lines.Add("")
    }
    Write-Log "存储设备信息收集完成" "OK"
} catch {
    $Lines.Add("  [读取失败] $_")
    Write-Log "存储设备信息读取失败: $_" "WARN"
}

# ---------------------------------------------------------------------------
# Network adapters (minimal, no IPs for privacy)
# ---------------------------------------------------------------------------
$Lines.Add("[网络适配器 (仅名称)]")
try {
    $NICs = Get-CimInstance -ClassName Win32_NetworkAdapter -ErrorAction Stop |
        Where-Object { $_.PhysicalAdapter -eq $true }
    foreach ($NIC in $NICs) {
        $Lines.Add("  $($NIC.Name) | $($NIC.AdapterType)")
    }
    Write-Log "网络适配器信息收集完成" "OK"
} catch {
    $Lines.Add("  [读取失败] $_")
}
$Lines.Add("")

# ---------------------------------------------------------------------------
# Power plan
# ---------------------------------------------------------------------------
$Lines.Add("[电源方案]")
try {
    $PowerPlan = powercfg /getactivescheme 2>$null
    $Lines.Add("  $PowerPlan")
} catch {
    $Lines.Add("  [读取失败]")
}
$Lines.Add("")

# ---------------------------------------------------------------------------
# Write files
# ---------------------------------------------------------------------------
$InfoPath = Join-Path $OutputDir "system_info.txt"
$Lines | Out-File -FilePath $InfoPath -Encoding UTF8
Write-Log "系统信息已写入: $InfoPath" "OK"

$SummaryPath = Join-Path $OutputDir "summary.txt"
$Summary | Out-File -FilePath $SummaryPath -Encoding UTF8
Write-Log "摘要已写入: $SummaryPath" "OK"

Write-Log "系统信息收集完成" "OK"
