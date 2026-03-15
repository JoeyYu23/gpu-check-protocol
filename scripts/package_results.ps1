#Requires -Version 5.0
<#
.SYNOPSIS
    Package the output directory into a zip file.
    打包验机结果为 ZIP 文件

.DESCRIPTION
    Compresses the timestamped output directory.
    Prints a final summary of what was collected.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputDir,
    [Parameter(Mandatory=$true)]
    [string]$Timestamp
)

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $color = switch ($Level) { "OK" { "Green" } "WARN" { "Yellow" } "ERROR" { "Red" } default { "Cyan" } }
    Write-Host "[$ts][$Level] $Message" -ForegroundColor $color
}

$OutputBase = Split-Path -Parent $OutputDir
$ZipName    = "gpu_check_${Timestamp}.zip"
$ZipPath    = Join-Path $OutputBase $ZipName

Write-Log "开始打包验机结果..." "INFO"

# Enumerate collected files
Write-Host ""
Write-Host "  收集到的文件:" -ForegroundColor Cyan
$Files = Get-ChildItem -Path $OutputDir -Recurse -File
$TotalSizeKB = 0

foreach ($File in $Files) {
    $SizeKB = [math]::Round($File.Length / 1KB, 1)
    $TotalSizeKB += $SizeKB
    $RelPath = $File.FullName.Replace($OutputDir, "").TrimStart('\')
    Write-Host ("  {0,-45} {1,8} KB" -f $RelPath, $SizeKB) -ForegroundColor White
}

Write-Host ""
Write-Host ("  共 {0} 个文件，总大小 {1} KB" -f $Files.Count, [math]::Round($TotalSizeKB, 1)) -ForegroundColor Cyan
Write-Host ""

# Create zip
try {
    if (Test-Path $ZipPath) {
        Remove-Item $ZipPath -Force
    }

    # Use .NET for zip (works on PS5+, no external tools needed)
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $OutputDir,
        $ZipPath,
        [System.IO.Compression.CompressionLevel]::Optimal,
        $false
    )

    $ZipSizeMB = [math]::Round((Get-Item $ZipPath).Length / 1MB, 2)
    Write-Log "打包完成: $ZipPath ($ZipSizeMB MB)" "OK"

} catch {
    Write-Log "ZIP 打包失败: $_" "ERROR"
    Write-Log "原始文件仍保存在: $OutputDir" "WARN"
    return
}

# Print final summary
$SummaryPath = Join-Path $OutputDir "test_summary.txt"
if (Test-Path $SummaryPath) {
    Write-Host ""
    Write-Host "  =============================================" -ForegroundColor DarkCyan
    Write-Host "  验机报告摘要" -ForegroundColor Cyan
    Write-Host "  =============================================" -ForegroundColor DarkCyan
    Get-Content $SummaryPath | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
}

Write-Host ""
Write-Host "  =============================================" -ForegroundColor Green
Write-Host "  打包完成！" -ForegroundColor Green
Write-Host "  ZIP 文件: $ZipPath" -ForegroundColor White
Write-Host "  大小:     $ZipSizeMB MB" -ForegroundColor White
Write-Host "  请将此 ZIP 文件发送给买家进行核验" -ForegroundColor Yellow
Write-Host "  =============================================" -ForegroundColor Green
