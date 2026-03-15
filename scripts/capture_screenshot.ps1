#Requires -Version 5.0
<#
.SYNOPSIS
    Capture a full-screen screenshot using .NET System.Drawing.
    使用 .NET 截取全屏截图

.DESCRIPTION
    No external tools required. Uses System.Drawing.Graphics.CopyFromScreen.
    Saves as PNG with timestamp and label.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputDir,
    [string]$Label = "screenshot"
)

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $color = switch ($Level) { "OK" { "Green" } "WARN" { "Yellow" } "ERROR" { "Red" } default { "Cyan" } }
    Write-Host "[$ts][$Level] $Message" -ForegroundColor $color
}

try {
    # Load required assemblies
    Add-Type -AssemblyName System.Drawing   -ErrorAction Stop
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
} catch {
    Write-Log "无法加载 System.Drawing 程序集: $_" "ERROR"
    exit 1
}

try {
    # Get total virtual screen bounds (covers all monitors)
    $Left   = [System.Windows.Forms.SystemInformation]::VirtualScreen.Left
    $Top    = [System.Windows.Forms.SystemInformation]::VirtualScreen.Top
    $Width  = [System.Windows.Forms.SystemInformation]::VirtualScreen.Width
    $Height = [System.Windows.Forms.SystemInformation]::VirtualScreen.Height

    # Create bitmap
    $Bitmap   = New-Object System.Drawing.Bitmap($Width, $Height)
    $Graphics = [System.Drawing.Graphics]::FromImage($Bitmap)

    # Capture screen
    $Graphics.CopyFromScreen(
        [System.Drawing.Point]::new($Left, $Top),
        [System.Drawing.Point]::new(0, 0),
        [System.Drawing.Size]::new($Width, $Height)
    )

    # Build filename
    $Ts       = Get-Date -Format "HHmmss"
    $SafeLabel = $Label -replace '[^\w\-]', '_'
    $Filename  = "screenshot_${Ts}_${SafeLabel}.png"
    $FilePath  = Join-Path $OutputDir $Filename

    # Save
    $Bitmap.Save($FilePath, [System.Drawing.Imaging.ImageFormat]::Png)
    $SizeKB = [math]::Round((Get-Item $FilePath).Length / 1KB, 1)
    Write-Log "截图已保存: $Filename ($SizeKB KB)" "OK"

} catch {
    Write-Log "截图失败: $_" "ERROR"
} finally {
    # Cleanup GDI objects
    if ($Graphics) { try { $Graphics.Dispose() } catch {} }
    if ($Bitmap)   { try { $Bitmap.Dispose()   } catch {} }
}
