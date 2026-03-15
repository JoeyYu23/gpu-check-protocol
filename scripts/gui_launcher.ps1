#Requires -Version 5.0
<#
.SYNOPSIS
    PC 验机工具 v2.0 - 图形界面启动器

.DESCRIPTION
    WinForms GUI for pc-check-protocol. Sellers double-click this
    instead of the batch file. Runs tests in a background runspace
    so the UI stays responsive.

    SAFETY: No network access, no personal file access, no uploads.

.PARAMETER ScriptRoot
    Path to the scripts/ directory. Defaults to the directory containing
    this file. Passed automatically by run_windows_gui.bat.

.NOTES
    Requires PowerShell 5.1 (Windows 10/11 built-in)
    Uses System.Windows.Forms and System.Drawing (.NET Framework)
#>

param(
    [string]$ScriptRoot = $PSScriptRoot
)

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ---------------------------------------------------------------------------
# Load WinForms assemblies
# ---------------------------------------------------------------------------
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------
if (-not $ScriptRoot) {
    $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
$RepoRoot = Split-Path -Parent $ScriptRoot

# ---------------------------------------------------------------------------
# Color / font constants
# ---------------------------------------------------------------------------
$ColorBlue      = [System.Drawing.Color]::FromArgb(33, 150, 243)   # #2196F3
$ColorGreen     = [System.Drawing.Color]::FromArgb(76, 175, 80)    # #4CAF50
$ColorGreenDark = [System.Drawing.Color]::FromArgb(56, 142, 60)    # darker green for hover
$ColorGray      = [System.Drawing.Color]::FromArgb(158, 158, 158)  # gray buttons
$ColorLogBg     = [System.Drawing.Color]::FromArgb(18, 18, 18)     # near-black log bg
$ColorLogFg     = [System.Drawing.Color]::FromArgb(204, 255, 204)  # light green log text
$ColorWhite     = [System.Drawing.Color]::White
$ColorLightGray = [System.Drawing.Color]::FromArgb(245, 245, 245)

$FontMain    = New-Object System.Drawing.Font("Microsoft YaHei UI", 10)
$FontHeader  = New-Object System.Drawing.Font("Microsoft YaHei UI", 14, [System.Drawing.FontStyle]::Bold)
$FontSub     = New-Object System.Drawing.Font("Microsoft YaHei UI", 8)
$FontBadge   = New-Object System.Drawing.Font("Microsoft YaHei UI", 9)
$FontButton  = New-Object System.Drawing.Font("Microsoft YaHei UI", 11, [System.Drawing.FontStyle]::Bold)
$FontLog     = New-Object System.Drawing.Font("Consolas", 9)

# ---------------------------------------------------------------------------
# Main form
# ---------------------------------------------------------------------------
$Form = New-Object System.Windows.Forms.Form
$Form.Text            = "PC 验机工具 v2.0"
$Form.Size            = New-Object System.Drawing.Size(600, 700)
$Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$Form.MaximizeBox     = $false
$Form.StartPosition   = [System.Windows.Forms.FormStartPosition]::CenterScreen
$Form.BackColor       = $ColorWhite
$Form.Font            = $FontMain

# ---------------------------------------------------------------------------
# 1. Header panel (blue, 70px)
# ---------------------------------------------------------------------------
$PanelHeader = New-Object System.Windows.Forms.Panel
$PanelHeader.Dock      = [System.Windows.Forms.DockStyle]::None
$PanelHeader.Location  = New-Object System.Drawing.Point(0, 0)
$PanelHeader.Size      = New-Object System.Drawing.Size(600, 70)
$PanelHeader.BackColor = $ColorBlue

$LabelTitle = New-Object System.Windows.Forms.Label
$LabelTitle.Text      = "PC 验机工具 v2.0"
$LabelTitle.Font      = $FontHeader
$LabelTitle.ForeColor = $ColorWhite
$LabelTitle.Location  = New-Object System.Drawing.Point(16, 8)
$LabelTitle.Size      = New-Object System.Drawing.Size(568, 28)
$LabelTitle.BackColor = [System.Drawing.Color]::Transparent

$LabelSubtitle = New-Object System.Windows.Forms.Label
$LabelSubtitle.Text      = "二手电脑交易验机  ·  安全开源  ·  不上传数据"
$LabelSubtitle.Font      = $FontSub
$LabelSubtitle.ForeColor = $ColorWhite
$LabelSubtitle.Location  = New-Object System.Drawing.Point(18, 38)
$LabelSubtitle.Size      = New-Object System.Drawing.Size(568, 20)
$LabelSubtitle.BackColor = [System.Drawing.Color]::Transparent

$PanelHeader.Controls.Add($LabelTitle)
$PanelHeader.Controls.Add($LabelSubtitle)
$Form.Controls.Add($PanelHeader)

# ---------------------------------------------------------------------------
# 2. Safety badge (green banner)
# ---------------------------------------------------------------------------
$PanelBadge = New-Object System.Windows.Forms.Panel
$PanelBadge.Location  = New-Object System.Drawing.Point(0, 70)
$PanelBadge.Size      = New-Object System.Drawing.Size(600, 30)
$PanelBadge.BackColor = $ColorGreen

$LabelBadge = New-Object System.Windows.Forms.Label
$LabelBadge.Text      = "√ 不联网  ·  不碰个人文件  ·  代码完全公开"
$LabelBadge.Font      = $FontBadge
$LabelBadge.ForeColor = $ColorWhite
$LabelBadge.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$LabelBadge.Dock      = [System.Windows.Forms.DockStyle]::Fill
$LabelBadge.BackColor = [System.Drawing.Color]::Transparent

$PanelBadge.Controls.Add($LabelBadge)
$Form.Controls.Add($PanelBadge)

# ---------------------------------------------------------------------------
# 3. Mode selection GroupBox
# ---------------------------------------------------------------------------
$GroupMode = New-Object System.Windows.Forms.GroupBox
$GroupMode.Text     = "选择测试模式"
$GroupMode.Location = New-Object System.Drawing.Point(16, 112)
$GroupMode.Size     = New-Object System.Drawing.Size(564, 155)
$GroupMode.Font     = $FontMain

$RadioQuick = New-Object System.Windows.Forms.RadioButton
$RadioQuick.Text     = "快速验机（约5分钟）— 系统信息 + 硬盘健康度"
$RadioQuick.Location = New-Object System.Drawing.Point(12, 22)
$RadioQuick.Size     = New-Object System.Drawing.Size(535, 24)
$RadioQuick.Font     = $FontMain

$RadioStandard = New-Object System.Windows.Forms.RadioButton
$RadioStandard.Text     = "标准验机（约15分钟）★ 推荐  —  系统信息 + GPU压力测试 + 硬盘SMART"
$RadioStandard.Location = New-Object System.Drawing.Point(12, 52)
$RadioStandard.Size     = New-Object System.Drawing.Size(535, 24)
$RadioStandard.Font     = New-Object System.Drawing.Font("Microsoft YaHei UI", 10, [System.Drawing.FontStyle]::Bold)
$RadioStandard.Checked  = $true   # default

$RadioFull = New-Object System.Windows.Forms.RadioButton
$RadioFull.Text     = "完整验机（约30-40分钟）— 全部测试项目"
$RadioFull.Location = New-Object System.Drawing.Point(12, 82)
$RadioFull.Size     = New-Object System.Drawing.Size(535, 24)
$RadioFull.Font     = $FontMain

$RadioCustom = New-Object System.Windows.Forms.RadioButton
$RadioCustom.Text     = "自定义 — 自选测试项目"
$RadioCustom.Location = New-Object System.Drawing.Point(12, 112)
$RadioCustom.Size     = New-Object System.Drawing.Size(535, 24)
$RadioCustom.Font     = $FontMain

$GroupMode.Controls.AddRange(@($RadioQuick, $RadioStandard, $RadioFull, $RadioCustom))
$Form.Controls.Add($GroupMode)

# ---------------------------------------------------------------------------
# 4. Custom options panel (hidden by default)
# ---------------------------------------------------------------------------
$GroupCustom = New-Object System.Windows.Forms.GroupBox
$GroupCustom.Text     = "自定义测试项目"
$GroupCustom.Location = New-Object System.Drawing.Point(16, 278)
$GroupCustom.Size     = New-Object System.Drawing.Size(564, 175)
$GroupCustom.Font     = $FontMain
$GroupCustom.Visible  = $false

$ChkFurmark = New-Object System.Windows.Forms.CheckBox
$ChkFurmark.Text     = "GPU 压力测试 (FurMark, 5分钟)"
$ChkFurmark.Location = New-Object System.Drawing.Point(12, 24)
$ChkFurmark.Size     = New-Object System.Drawing.Size(400, 22)
$ChkFurmark.Checked  = $true

$ChkVram = New-Object System.Windows.Forms.CheckBox
$ChkVram.Text     = "VRAM 显存测试 (OCCT, 10分钟)"
$ChkVram.Location = New-Object System.Drawing.Point(12, 50)
$ChkVram.Size     = New-Object System.Drawing.Size(400, 22)
$ChkVram.Checked  = $true

$ChkCpu = New-Object System.Windows.Forms.CheckBox
$ChkCpu.Text     = "CPU 压力测试 (10分钟)"
$ChkCpu.Location = New-Object System.Drawing.Point(12, 76)
$ChkCpu.Size     = New-Object System.Drawing.Size(400, 22)
$ChkCpu.Checked  = $true

$ChkMemory = New-Object System.Windows.Forms.CheckBox
$ChkMemory.Text     = "内存稳定性测试 (5分钟)"
$ChkMemory.Location = New-Object System.Drawing.Point(12, 102)
$ChkMemory.Size     = New-Object System.Drawing.Size(400, 22)
$ChkMemory.Checked  = $true

$ChkDisk = New-Object System.Windows.Forms.CheckBox
$ChkDisk.Text     = "硬盘 SMART 健康度 (无需额外工具)"
$ChkDisk.Location = New-Object System.Drawing.Point(12, 128)
$ChkDisk.Size     = New-Object System.Drawing.Size(400, 22)
$ChkDisk.Checked  = $true

$ChkThermal = New-Object System.Windows.Forms.CheckBox
$ChkThermal.Text     = "散热综合评估 (CPU+GPU同时满载, 10分钟)"
$ChkThermal.Location = New-Object System.Drawing.Point(12, 154)
$ChkThermal.Size     = New-Object System.Drawing.Size(400, 22)
$ChkThermal.Checked  = $true

$GroupCustom.Controls.AddRange(@($ChkFurmark, $ChkVram, $ChkCpu, $ChkMemory, $ChkDisk, $ChkThermal))
$Form.Controls.Add($GroupCustom)

# ---------------------------------------------------------------------------
# Helper: Y position for elements below mode/custom panels
# ---------------------------------------------------------------------------
$BaseY_Normal = 282    # GroupMode bottom (112+155+15)
$BaseY_Custom = 465    # GroupCustom bottom (278+175+12)

# ---------------------------------------------------------------------------
# 5. Progress area (hidden initially)
# ---------------------------------------------------------------------------
$PanelProgress = New-Object System.Windows.Forms.Panel
$PanelProgress.Location = New-Object System.Drawing.Point(16, $BaseY_Normal)
$PanelProgress.Size     = New-Object System.Drawing.Size(564, 180)
$PanelProgress.Visible  = $false
$PanelProgress.BackColor = $ColorWhite

$LabelStep = New-Object System.Windows.Forms.Label
$LabelStep.Text      = "正在收集系统信息..."
$LabelStep.Location  = New-Object System.Drawing.Point(0, 0)
$LabelStep.Size      = New-Object System.Drawing.Size(564, 22)
$LabelStep.Font      = $FontMain
$LabelStep.ForeColor = [System.Drawing.Color]::FromArgb(33, 33, 33)

$ProgressBar = New-Object System.Windows.Forms.ProgressBar
$ProgressBar.Location = New-Object System.Drawing.Point(0, 26)
$ProgressBar.Size     = New-Object System.Drawing.Size(564, 20)
$ProgressBar.Minimum  = 0
$ProgressBar.Maximum  = 100
$ProgressBar.Value    = 0
$ProgressBar.Style    = [System.Windows.Forms.ProgressBarStyle]::Continuous

$RichLog = New-Object System.Windows.Forms.RichTextBox
$RichLog.Location    = New-Object System.Drawing.Point(0, 52)
$RichLog.Size        = New-Object System.Drawing.Size(564, 128)
$RichLog.ReadOnly    = $true
$RichLog.BackColor   = $ColorLogBg
$RichLog.ForeColor   = $ColorLogFg
$RichLog.Font        = $FontLog
$RichLog.ScrollBars  = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical
$RichLog.WordWrap    = $true

$PanelProgress.Controls.AddRange(@($LabelStep, $ProgressBar, $RichLog))
$Form.Controls.Add($PanelProgress)

# ---------------------------------------------------------------------------
# 6. Buttons
# ---------------------------------------------------------------------------
$BtnStart = New-Object System.Windows.Forms.Button
$BtnStart.Text      = "开始验机"
$BtnStart.Location  = New-Object System.Drawing.Point(180, 580)
$BtnStart.Size      = New-Object System.Drawing.Size(220, 46)
$BtnStart.Font      = $FontButton
$BtnStart.BackColor = $ColorGreen
$BtnStart.ForeColor = $ColorWhite
$BtnStart.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$BtnStart.FlatAppearance.BorderSize  = 0
$BtnStart.FlatAppearance.MouseOverBackColor = $ColorGreenDark
$BtnStart.Cursor    = [System.Windows.Forms.Cursors]::Hand

$BtnOpenFolder = New-Object System.Windows.Forms.Button
$BtnOpenFolder.Text      = "打开结果文件夹"
$BtnOpenFolder.Location  = New-Object System.Drawing.Point(180, 532)
$BtnOpenFolder.Size      = New-Object System.Drawing.Size(220, 36)
$BtnOpenFolder.Font      = $FontMain
$BtnOpenFolder.BackColor = $ColorBlue
$BtnOpenFolder.ForeColor = $ColorWhite
$BtnOpenFolder.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$BtnOpenFolder.FlatAppearance.BorderSize = 0
$BtnOpenFolder.Cursor    = [System.Windows.Forms.Cursors]::Hand
$BtnOpenFolder.Visible   = $false

$BtnExit = New-Object System.Windows.Forms.Button
$BtnExit.Text      = "退出"
$BtnExit.Location  = New-Object System.Drawing.Point(504, 580)
$BtnExit.Size      = New-Object System.Drawing.Size(72, 46)
$BtnExit.Font      = $FontMain
$BtnExit.BackColor = $ColorGray
$BtnExit.ForeColor = $ColorWhite
$BtnExit.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$BtnExit.FlatAppearance.BorderSize = 0
$BtnExit.Cursor    = [System.Windows.Forms.Cursors]::Hand

$Form.Controls.AddRange(@($BtnStart, $BtnOpenFolder, $BtnExit))

# ---------------------------------------------------------------------------
# State variable for output directory (set when tests start)
# ---------------------------------------------------------------------------
$Script:OutputDir = $null

# ---------------------------------------------------------------------------
# Helper: append text to the log box (thread-safe via Invoke)
# ---------------------------------------------------------------------------
function Append-Log {
    param([string]$Text)
    if ($RichLog.InvokeRequired) {
        $RichLog.Invoke([Action[string]] {
            param($t)
            $RichLog.AppendText($t + "`n")
            $RichLog.ScrollToCaret()
        }, $Text)
    } else {
        $RichLog.AppendText($Text + "`n")
        $RichLog.ScrollToCaret()
    }
}

# ---------------------------------------------------------------------------
# Helper: update step label (thread-safe)
# ---------------------------------------------------------------------------
function Set-StepLabel {
    param([string]$Text)
    if ($LabelStep.InvokeRequired) {
        $LabelStep.Invoke([Action[string]] {
            param($t) $LabelStep.Text = $t
        }, $Text)
    } else {
        $LabelStep.Text = $Text
    }
}

# ---------------------------------------------------------------------------
# Helper: set progress bar value (thread-safe)
# ---------------------------------------------------------------------------
function Set-Progress {
    param([int]$Value)
    $clamped = [Math]::Max(0, [Math]::Min(100, $Value))
    if ($ProgressBar.InvokeRequired) {
        $ProgressBar.Invoke([Action[int]] {
            param($v) $ProgressBar.Value = $v
        }, $clamped)
    } else {
        $ProgressBar.Value = $clamped
    }
}

# ---------------------------------------------------------------------------
# Show / hide custom panel and reflow progress area + buttons
# ---------------------------------------------------------------------------
function Update-Layout {
    $showCustom = $RadioCustom.Checked

    $GroupCustom.Visible = $showCustom

    $progressY = if ($showCustom) { $BaseY_Custom } else { $BaseY_Normal }

    $PanelProgress.Location = New-Object System.Drawing.Point(16, $progressY)

    if ($PanelProgress.Visible) {
        $buttonY        = $progressY + 180 + 12
        $openFolderY    = $buttonY - 48
        $newFormHeight  = $buttonY + 46 + 40
    } else {
        $buttonY        = $progressY + 12
        $openFolderY    = $buttonY - 48
        $newFormHeight  = $buttonY + 46 + 40
    }

    $BtnStart.Location      = New-Object System.Drawing.Point(180, $buttonY)
    $BtnExit.Location       = New-Object System.Drawing.Point(504, $buttonY)
    $BtnOpenFolder.Location = New-Object System.Drawing.Point(180, $openFolderY)
    $Form.ClientSize        = New-Object System.Drawing.Size(600, ($newFormHeight))
}

# Wire up radio buttons to layout update
$RadioCustom.Add_CheckedChanged({ Update-Layout })
$RadioQuick.Add_CheckedChanged({ Update-Layout })
$RadioStandard.Add_CheckedChanged({ Update-Layout })
$RadioFull.Add_CheckedChanged({ Update-Layout })

# Initial layout
Update-Layout

# ---------------------------------------------------------------------------
# Build test flags from GUI selections
# ---------------------------------------------------------------------------
function Get-TestFlags {
    $flags = @{
        RunFurmark       = $false
        RunOcctVram      = $false
        RunCpuStress     = $false
        RunMemoryTest    = $false
        RunDiskHealth    = $false
        RunThermalStress = $false
        TestMode         = "standard"
    }

    if ($RadioQuick.Checked) {
        $flags.RunDiskHealth = $true
        $flags.TestMode      = "quick"
    } elseif ($RadioStandard.Checked) {
        $flags.RunFurmark    = $true
        $flags.RunDiskHealth = $true
        $flags.TestMode      = "standard"
    } elseif ($RadioFull.Checked) {
        $flags.RunFurmark       = $true
        $flags.RunOcctVram      = $true
        $flags.RunCpuStress     = $true
        $flags.RunMemoryTest    = $true
        $flags.RunDiskHealth    = $true
        $flags.TestMode         = "full"
    } elseif ($RadioCustom.Checked) {
        $flags.RunFurmark       = $ChkFurmark.Checked
        $flags.RunOcctVram      = $ChkVram.Checked
        $flags.RunCpuStress     = $ChkCpu.Checked
        $flags.RunMemoryTest    = $ChkMemory.Checked
        $flags.RunDiskHealth    = $ChkDisk.Checked
        $flags.RunThermalStress = $ChkThermal.Checked
        $flags.TestMode         = "custom"
    }
    return $flags
}

# ---------------------------------------------------------------------------
# Build -CustomTests string for run_windows.ps1
# ---------------------------------------------------------------------------
function Build-CustomTestsParam {
    param($Flags)
    $parts = @()
    if ($Flags.RunFurmark)       { $parts += "furmark" }
    if ($Flags.RunOcctVram)      { $parts += "vram" }
    if ($Flags.RunCpuStress)     { $parts += "cpu" }
    if ($Flags.RunMemoryTest)    { $parts += "memory" }
    if ($Flags.RunDiskHealth)    { $parts += "disk" }
    if ($Flags.RunThermalStress) { $parts += "thermal" }
    return ($parts -join ",")
}

# ---------------------------------------------------------------------------
# Background runspace — runs tests without freezing the GUI
# ---------------------------------------------------------------------------
function Start-TestsInBackground {
    param($Flags)

    $runWindowsScript = Join-Path $ScriptRoot "run_windows.ps1"

    # Shared data: the runspace writes to a synchronized queue,
    # a timer on the main thread drains it into the log box.
    $queue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
    $Script:BgQueue = $queue

    # Build arguments for run_windows.ps1
    $customParam = Build-CustomTestsParam -Flags $Flags
    $testMode    = $Flags.TestMode

    # Create runspace
    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = [System.Threading.ApartmentState]::STA
    $rs.ThreadOptions  = [System.Management.Automation.Runspaces.PSThreadOptions]::ReuseThread
    $rs.Open()

    # Pass variables into the runspace
    $rs.SessionStateProxy.SetVariable("RunWindowsScript", $runWindowsScript)
    $rs.SessionStateProxy.SetVariable("ScriptRootPath",   $ScriptRoot)
    $rs.SessionStateProxy.SetVariable("RepoRootPath",     $RepoRoot)
    $rs.SessionStateProxy.SetVariable("TestMode",         $testMode)
    $rs.SessionStateProxy.SetVariable("CustomTests",      $customParam)
    $rs.SessionStateProxy.SetVariable("LogQueue",         $queue)

    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs

    $scriptBlock = {
        $ErrorActionPreference = "Continue"
        Set-StrictMode -Off

        function Queue-Log {
            param([string]$msg)
            $LogQueue.Enqueue($msg)
        }

        Queue-Log "=== 开始验机 ==="
        Queue-Log "脚本路径: $RunWindowsScript"
        Queue-Log "测试模式: $TestMode"
        if ($CustomTests) { Queue-Log "自定义项目: $CustomTests" }
        Queue-Log ""

        try {
            # Run the orchestrator with -NonInteractive
            $argList = @(
                "-NoProfile",
                "-ExecutionPolicy", "Bypass",
                "-File", $RunWindowsScript,
                "-ScriptRoot", $ScriptRootPath,
                "-NonInteractive",
                "-TestMode", $TestMode
            )
            if ($CustomTests) {
                $argList += @("-CustomTests", $CustomTests)
            }

            $proc = New-Object System.Diagnostics.Process
            $proc.StartInfo.FileName               = "powershell.exe"
            $proc.StartInfo.Arguments              = ($argList -join " ")
            $proc.StartInfo.UseShellExecute        = $false
            $proc.StartInfo.RedirectStandardOutput = $true
            $proc.StartInfo.RedirectStandardError  = $true
            $proc.StartInfo.CreateNoWindow         = $true
            $proc.StartInfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
            $proc.StartInfo.StandardErrorEncoding  = [System.Text.Encoding]::UTF8

            $outputSb  = [System.Text.StringBuilder]::new()
            $proc.Add_OutputDataReceived({
                param($s, $e)
                if ($null -ne $e.Data) {
                    $LogQueue.Enqueue($e.Data)
                }
            })
            $proc.Add_ErrorDataReceived({
                param($s, $e)
                if ($null -ne $e.Data) {
                    $LogQueue.Enqueue("[STDERR] " + $e.Data)
                }
            })

            $proc.Start() | Out-Null
            $proc.BeginOutputReadLine()
            $proc.BeginErrorReadLine()
            $proc.WaitForExit()

            Queue-Log ""
            if ($proc.ExitCode -eq 0) {
                Queue-Log "=== 验机完成 (退出码: 0) ==="
            } else {
                Queue-Log "=== 验机结束 (退出码: $($proc.ExitCode)) ==="
            }
        } catch {
            Queue-Log "[ERROR] 启动测试脚本失败: $_"
        }

        # Signal completion
        $LogQueue.Enqueue("__DONE__")
    }

    $ps.AddScript($scriptBlock) | Out-Null
    $Script:BgPowerShell = $ps
    $Script:BgRunspace   = $rs

    $null = $ps.BeginInvoke()
}

# ---------------------------------------------------------------------------
# Timer: drain the queue into the log box + detect completion
# ---------------------------------------------------------------------------
$Timer = New-Object System.Windows.Forms.Timer
$Timer.Interval = 150   # poll every 150 ms
$Script:ProgressStep = 0
$Script:TotalSteps   = 6

$Timer.Add_Tick({
    if ($null -eq $Script:BgQueue) { return }

    $item = $null
    $count = 0
    while ($Script:BgQueue.TryDequeue([ref]$item) -and $count -lt 40) {
        $count++
        if ($item -eq "__DONE__") {
            # Tests finished
            $Timer.Stop()
            Set-Progress 100
            Set-StepLabel "验机完成！"
            $BtnStart.Enabled = $true
            $BtnStart.Text    = "重新验机"
            $BtnOpenFolder.Visible = $true

            # Locate the output directory from the transcript
            $outputBase = Join-Path $RepoRoot "output"
            if (Test-Path $outputBase) {
                $latest = Get-ChildItem $outputBase -Directory |
                          Sort-Object LastWriteTime -Descending |
                          Select-Object -First 1
                if ($latest) { $Script:OutputDir = $latest.FullName }
            }
            Append-Log ""
            Append-Log ">>> 验机完成！结果保存在: $Script:OutputDir"
            continue
        }

        # Update progress heuristically based on keywords
        if ($item -match "系统信息收集") {
            $Script:ProgressStep = 1
            Set-StepLabel "正在收集系统信息..."
        } elseif ($item -match "GPU 压力测试|FurMark") {
            $Script:ProgressStep = 2
            Set-StepLabel "正在运行 GPU 压力测试..."
        } elseif ($item -match "VRAM|OCCT") {
            $Script:ProgressStep = 3
            Set-StepLabel "正在运行 VRAM 显存测试..."
        } elseif ($item -match "CPU 压力") {
            $Script:ProgressStep = 4
            Set-StepLabel "正在运行 CPU 压力测试..."
        } elseif ($item -match "内存稳定性") {
            $Script:ProgressStep = 4
            Set-StepLabel "正在运行内存稳定性测试..."
        } elseif ($item -match "硬盘 SMART|硬盘健康") {
            $Script:ProgressStep = 5
            Set-StepLabel "正在检查硬盘健康度..."
        } elseif ($item -match "散热综合") {
            $Script:ProgressStep = 5
            Set-StepLabel "正在进行散热综合评估..."
        } elseif ($item -match "打包结果") {
            $Script:ProgressStep = 6
            Set-StepLabel "正在打包结果..."
        }

        $pct = [int](($Script:ProgressStep / $Script:TotalSteps) * 95)
        Set-Progress $pct
        Append-Log $item
    }
})

# ---------------------------------------------------------------------------
# Button: Start
# ---------------------------------------------------------------------------
$BtnStart.Add_Click({
    # Disable controls while running
    $BtnStart.Enabled      = $false
    $BtnStart.Text         = "验机中..."
    $BtnOpenFolder.Visible = $false
    $GroupMode.Enabled     = $false
    $GroupCustom.Enabled   = $false

    # Show progress area
    $PanelProgress.Visible = $true
    Update-Layout

    # Clear log
    $RichLog.Clear()
    Set-Progress 0
    Set-StepLabel "正在初始化..."
    $Script:ProgressStep = 0
    $Script:OutputDir    = $null

    $flags = Get-TestFlags
    Start-TestsInBackground -Flags $flags

    $Timer.Start()
})

# ---------------------------------------------------------------------------
# Button: Open folder
# ---------------------------------------------------------------------------
$BtnOpenFolder.Add_Click({
    if ($Script:OutputDir -and (Test-Path $Script:OutputDir)) {
        Start-Process explorer.exe $Script:OutputDir
    } else {
        $outputBase = Join-Path $RepoRoot "output"
        if (Test-Path $outputBase) {
            Start-Process explorer.exe $outputBase
        } else {
            [System.Windows.Forms.MessageBox]::Show(
                "找不到输出目录。请确认验机已完成。",
                "提示",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
    }
})

# ---------------------------------------------------------------------------
# Button: Exit
# ---------------------------------------------------------------------------
$BtnExit.Add_Click({
    $Timer.Stop()
    if ($Script:BgPowerShell) {
        try { $Script:BgPowerShell.Stop() } catch {}
    }
    if ($Script:BgRunspace) {
        try { $Script:BgRunspace.Close() } catch {}
    }
    $Form.Close()
})

# ---------------------------------------------------------------------------
# Form closing cleanup
# ---------------------------------------------------------------------------
$Form.Add_FormClosing({
    $Timer.Stop()
    if ($Script:BgPowerShell) {
        try { $Script:BgPowerShell.Stop() } catch {}
    }
    if ($Script:BgRunspace) {
        try { $Script:BgRunspace.Close() } catch {}
    }
})

# ---------------------------------------------------------------------------
# Run the GUI
# ---------------------------------------------------------------------------
[System.Windows.Forms.Application]::Run($Form)
