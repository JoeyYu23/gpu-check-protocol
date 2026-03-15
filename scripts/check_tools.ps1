#Requires -Version 5.0
<#
.SYNOPSIS
    Check and auto-download benchmark tools to tools/ directory.
    自动检查并下载验机工具

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

function Download-Tool {
    param(
        [string]$Name,
        [string]$Url,
        [string]$DestPath,
        [bool]$IsZip = $false
    )

    $ToolsDir = Join-Path $RepoRoot "tools"
    if (-not (Test-Path $ToolsDir)) { New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null }

    $TempDir = Join-Path $env:TEMP "gpu-check-downloads"
    if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }

    try {
        if ($IsZip) {
            $ZipPath = Join-Path $TempDir "$Name.zip"
            Write-Log "  正在下载 $Name (ZIP)..." "INFO"

            # Use TLS 1.2
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
            $wc.DownloadFile($Url, $ZipPath)

            # Extract
            $ExtractDir = Join-Path $TempDir "$Name-extracted"
            if (Test-Path $ExtractDir) { Remove-Item $ExtractDir -Recurse -Force }

            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $ExtractDir)

            # Find the target exe in extracted files
            $TargetExe = Split-Path -Leaf $DestPath
            $Found = Get-ChildItem -Path $ExtractDir -Recurse -Filter $TargetExe | Select-Object -First 1

            if ($Found) {
                $DestDir = Split-Path -Parent $DestPath
                if (-not (Test-Path $DestDir)) { New-Item -ItemType Directory -Path $DestDir -Force | Out-Null }
                Copy-Item $Found.FullName $DestPath -Force
                Write-Log "  $Name 下载解压完成" "OK"
                return $true
            } else {
                Write-Log "  ZIP 中未找到 $TargetExe" "WARN"
                return $false
            }
        } else {
            # Direct exe download
            Write-Log "  正在下载 $Name..." "INFO"

            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

            $DestDir = Split-Path -Parent $DestPath
            if (-not (Test-Path $DestDir)) { New-Item -ItemType Directory -Path $DestDir -Force | Out-Null }

            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
            $wc.DownloadFile($Url, $DestPath)

            if (Test-Path $DestPath) {
                $SizeMB = [math]::Round((Get-Item $DestPath).Length / 1MB, 1)
                Write-Log "  $Name 下载完成 ($SizeMB MB)" "OK"
                return $true
            }
            return $false
        }
    } catch {
        Write-Log "  $Name 自动下载失败: $($_.Exception.Message)" "WARN"
        return $false
    }
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

# Download config: which tools can be auto-downloaded
$AutoDownload = @{
    "GPU-Z" = @{
        Url = "https://download.techpowerup.com/files/GPU-Z.2.61.0.exe"
        IsZip = $false
    }
    "CPU-Z" = @{
        Url = "https://download.cpuid.com/cpu-z/cpu-z_2.12-en.zip"
        IsZip = $true
    }
    "HWiNFO64" = @{
        Url = "https://www.hwinfo.com/files/hwi_800.exe"
        IsZip = $false
    }
}

$Status = @{}

Write-Log "检查工具目录..." "INFO"
Write-Host ""

# First pass: check what's already there
foreach ($ToolName in $ToolPaths.Keys) {
    $Path = $ToolPaths[$ToolName]
    $Status[$ToolName] = Test-Path $Path
}

# Second pass: auto-download missing tools that support it
$MissingAutoDownloadable = $Status.Keys | Where-Object { -not $Status[$_] -and $AutoDownload.ContainsKey($_) }
if ($MissingAutoDownloadable.Count -gt 0) {
    Write-Log "正在自动下载缺失的工具..." "INFO"
    Write-Host ""

    foreach ($ToolName in $MissingAutoDownloadable) {
        $DlConfig = $AutoDownload[$ToolName]
        $DestPath = $ToolPaths[$ToolName]
        $Result = Download-Tool -Name $ToolName -Url $DlConfig.Url -DestPath $DestPath -IsZip $DlConfig.IsZip
        $Status[$ToolName] = $Result
    }
    Write-Host ""
}

# Display final status
Write-Host "  工具名称        状态      路径" -ForegroundColor DarkCyan
Write-Host "  $('-' * 60)" -ForegroundColor DarkCyan

foreach ($ToolName in $ToolPaths.Keys) {
    $Path  = $ToolPaths[$ToolName]
    $Found = $Status[$ToolName]

    if ($Found) {
        $FileInfo = Get-Item $Path
        $SizeMB   = [math]::Round($FileInfo.Length / 1MB, 1)
        Write-Host ("  {0,-16} " -f $ToolName) -NoNewline
        Write-Host ("[OK]      " ) -ForegroundColor Green -NoNewline
        Write-Host "$Path ($SizeMB MB)"
    } else {
        Write-Host ("  {0,-16} " -f $ToolName) -NoNewline
        Write-Host ("[缺失]    " ) -ForegroundColor Yellow -NoNewline
        Write-Host "$Path"
    }
}

Write-Host ""

# Report still-missing tools with manual download instructions
$StillMissing = $Status.Keys | Where-Object { -not $Status[$_] }
if ($StillMissing.Count -gt 0) {
    Write-Host "  以下工具需要手动下载（不支持自动下载）:" -ForegroundColor Yellow
    foreach ($ToolName in $StillMissing) {
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
    Write-Log "部分工具缺失，相关测试将被跳过（不影响其他测试）" "WARN"
} else {
    Write-Log "所有工具均已就绪" "OK"
}

# Return status hashtable
return $Status
