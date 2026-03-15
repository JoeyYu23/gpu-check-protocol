#Requires -Version 5.0
<#
.SYNOPSIS
    Check which benchmark tools are present in the tools/ directory.
    检查工具目录中的程序是否存在

.OUTPUTS
    Hashtable: { "ToolName" = $true/$false }
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$RepoRoot
)

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $color = switch ($Level) { "OK" { "Green" } "WARN" { "Yellow" } "ERROR" { "Red" } default { "Cyan" } }
    Write-Host "[$ts][$Level] $Message" -ForegroundColor $color
}

# Load tool URL config
$UrlConfigPath = Join-Path $RepoRoot "config\tool_urls.json"
$UrlConfig = $null
if (Test-Path $UrlConfigPath) {
    try { $UrlConfig = Get-Content $UrlConfigPath -Raw | ConvertFrom-Json } catch {}
}

# Expected paths for each tool
$ToolPaths = @{
    "GPU-Z"    = Join-Path $RepoRoot "tools\GPU-Z.exe"
    "CPU-Z"    = Join-Path $RepoRoot "tools\cpuz_x64.exe"
    "HWiNFO64" = Join-Path $RepoRoot "tools\HWiNFO64.exe"
    "FurMark"  = Join-Path $RepoRoot "tools\FurMark\FurMark.exe"
    "OCCT"     = Join-Path $RepoRoot "tools\OCCT\OCCT.exe"
}

$Status = @{}

Write-Log "检查工具目录..." "INFO"
Write-Host ""
Write-Host "  工具名称        状态      路径" -ForegroundColor DarkCyan
Write-Host "  " + "-" * 55 -ForegroundColor DarkCyan

foreach ($ToolName in $ToolPaths.Keys) {
    $Path   = $ToolPaths[$ToolName]
    $Found  = Test-Path $Path
    $Status[$ToolName] = $Found

    if ($Found) {
        $FileInfo = Get-Item $Path
        $SizeMB   = [math]::Round($FileInfo.Length / 1MB, 1)
        Write-Host ("  {0,-16} " -f $ToolName) -NoNewline
        Write-Host ("[找到]    " ) -ForegroundColor Green -NoNewline
        Write-Host "$Path ($SizeMB MB)"
    } else {
        Write-Host ("  {0,-16} " -f $ToolName) -NoNewline
        Write-Host ("[缺失]    " ) -ForegroundColor Yellow -NoNewline
        Write-Host "$Path"
    }
}

Write-Host ""

# Report missing tools with download instructions
$MissingTools = $Status.Keys | Where-Object { -not $Status[$_] }
if ($MissingTools.Count -gt 0) {
    Write-Host "  缺失工具下载地址:" -ForegroundColor Yellow
    foreach ($ToolName in $MissingTools) {
        if ($UrlConfig -and $UrlConfig.tools.$ToolName) {
            $ToolInfo = $UrlConfig.tools.$ToolName
            Write-Host "  - $ToolName`: $($ToolInfo.url)" -ForegroundColor DarkYellow
            if ($ToolInfo.note) {
                Write-Host "    备注: $($ToolInfo.note)" -ForegroundColor Gray
            }
        } else {
            Write-Host "  - $ToolName`: 请参考 README.md 获取下载链接" -ForegroundColor DarkYellow
        }
    }
    Write-Host ""
    Write-Log "部分工具缺失，相关测试将被跳过" "WARN"
} else {
    Write-Log "所有工具均已就绪" "OK"
}

# Return status hashtable
return $Status
