# PC Check Protocol

**二手电脑交易验机工具**

一键收集硬件信息、运行多项压力测试、打包结果，帮助买卖双方在交易现场快速完成整机验机。适用于各类台式机与笔记本（含 GPU、CPU、内存、硬盘全面检测）。

**Used-PC verification tool for buyers and sellers — collects hardware info, runs stress tests (GPU, CPU, memory, disk), and packages results for review.**

---

## 安全声明 / Safety Statement

- **不联网、不上传**：所有数据只保存在本机 `output/` 目录，不发送到任何服务器
- **不访问个人文件**：只读取硬件信息（型号、驱动版本、温度），不碰文档、图片、密码
- **不留后台服务**：脚本运行完毕即结束，不安装任何常驻程序
- **不修改系统设置**（除 HWiNFO64 的 CSV 记录注册表项，测试后可手动删除）
- **开源可审计**：所有 `.ps1` 脚本均为明文 PowerShell，可用记事本打开查看

---

- **No network access, no uploads** — all data stays in the local `output/` directory
- **No personal file access** — only reads hardware info (model, driver version, temperatures)
- **No background services** — script exits cleanly after completion, installs nothing
- **No system setting changes** (except HWiNFO64's CSV logging registry key, removable manually)
- **Open source and auditable** — all `.ps1` scripts are plain PowerShell, readable in Notepad

---

## 测试模式 / Test Modes

启动后会出现交互菜单，选择测试模式：

| 模式 | 时长 | 包含项目 |
|------|------|---------|
| **[1] 快速验机** | ~5 分钟 | 系统信息 + 硬盘 SMART |
| **[2] 标准验机 ★ 推荐** | ~15 分钟 | 系统信息 + GPU压力测试 + 硬盘 SMART |
| **[3] 完整验机** | ~30-40 分钟 | 系统信息 + GPU压力 + VRAM测试 + CPU压力 + 内存测试 + 硬盘 SMART |
| **[4] 自定义** | 按选项而定 | 自选任意测试项目 |

An interactive menu appears at startup — select the verification depth you need.

---

## GUI 模式（推荐新手）

**双击 `run_windows_gui.bat`** 即可打开图形界面，无需命令行知识。

```
┌─────────────────────────────────────────────┐
│  PC 验机工具 v2.0                            │  ← 蓝色标题栏
│  二手电脑交易验机 · 安全开源 · 不上传数据    │
├─────────────────────────────────────────────┤
│  √ 不联网 · 不碰个人文件 · 代码完全公开      │  ← 绿色安全标识
├─────────────────────────────────────────────┤
│  选择测试模式                                │
│  ○ 快速验机（约5分钟）                       │
│  ● 标准验机（约15分钟）★ 推荐               │  ← 默认选中
│  ○ 完整验机（约30-40分钟）                   │
│  ○ 自定义                                    │
├─────────────────────────────────────────────┤
│  [进度条]                                    │  ← 点击开始后显示
│  实时日志输出...                             │
├─────────────────────────────────────────────┤
│           [ 开始验机 ]           [ 退出 ]    │
└─────────────────────────────────────────────┘
```

**界面特点：**
- 中文全程提示，不出现黑色命令行窗口
- 测试在后台运行，界面始终可响应
- 实时日志滚动显示当前进度
- 完成后一键打开结果文件夹

**打包成 EXE（可选）：** 如需分发给完全不懂电脑的用户，运行 `build_exe.ps1` 将工具打包为单个 `PC验机工具.exe`：

```powershell
# 右键 build_exe.ps1 → "用 PowerShell 运行"
# 首次运行会自动安装 ps2exe 模块（需联网）
# 生成 PC验机工具.exe，可单独复制给买家
```

> 注意：EXE 打包需要 ps2exe 模块（`Install-Module ps2exe`）。目标机器需 Windows 10/11 和 .NET Framework 4.5+（系统自带）。

---

## GUI Mode (Recommended for beginners)

**Double-click `run_windows_gui.bat`** to open the graphical interface — no command-line knowledge needed.

The window shows:
- Blue header with tool name and subtitle
- Green safety badge confirming no network access
- Radio buttons for test mode selection (Standard is pre-selected)
- Optional custom test checkboxes (shown when "Custom" is selected)
- Real-time log output area with progress bar (appears after clicking Start)
- "Open Results Folder" button after completion

**Build as EXE (optional):** Run `build_exe.ps1` to compile the GUI into a standalone `PC验机工具.exe` using ps2exe.

---

## 快速开始（3步）

### 第一步：下载本工具

从 GitHub 页面点 **Code → Download ZIP**，解压到任意目录。

### 第二步：下载测试工具

将以下工具放入 `tools/` 目录（见下方下载链接表）：

| 工具 | 放置路径 | 用途 |
|------|---------|------|
| GPU-Z.exe | `tools/GPU-Z.exe` | 显卡信息读取 |
| cpuz_x64.exe | `tools/cpuz_x64.exe` | CPU/内存信息 |
| HWiNFO64.exe | `tools/HWiNFO64.exe` | 传感器实时记录（温度/功耗）|
| FurMark.exe | `tools/FurMark/FurMark.exe` | GPU 烤机压力测试 |
| OCCT.exe | `tools/OCCT/OCCT.exe` | VRAM / CPU / 内存压力测试 |
| DiskInfo64.exe | `tools/CrystalDiskInfo/DiskInfo64.exe` | 硬盘 SMART 详情（可选）|

### 第三步：运行验机

- **图形界面（推荐）：双击 `run_windows_gui.bat`**
- **命令行模式：双击 `run_windows.bat`**（右键"以管理员身份运行"以获取完整硬件数据）

验机完成后，结果保存在 `output/<时间戳>/` 目录，并自动打包为 ZIP。

---

## Quick Start (3 Steps)

### Step 1: Download this tool

Click **Code → Download ZIP** on the GitHub page and extract to any folder.

### Step 2: Download test utilities

Place the following tools in the `tools/` directory (download links below):

| Tool | Path | Purpose |
|------|------|---------|
| GPU-Z.exe | `tools/GPU-Z.exe` | GPU info (model, VRAM, driver) |
| cpuz_x64.exe | `tools/cpuz_x64.exe` | CPU / RAM info |
| HWiNFO64.exe | `tools/HWiNFO64.exe` | Real-time sensor logging (temp, power) |
| FurMark.exe | `tools/FurMark/FurMark.exe` | GPU stress test |
| OCCT.exe | `tools/OCCT/OCCT.exe` | VRAM / CPU / memory stress tests |
| DiskInfo64.exe | `tools/CrystalDiskInfo/DiskInfo64.exe` | Disk SMART detail (optional) |

### Step 3: Run verification

- **GUI mode (recommended): Double-click `run_windows_gui.bat`**
- **CLI mode: Double-click `run_windows.bat`** (right-click → "Run as Administrator" for full hardware data)

Results are saved to `output/<timestamp>/` and automatically zipped.

---

## 工具下载链接 / Tool Download Links

| 工具 / Tool | 下载地址 / Download | 是否必须 / Required | 说明 / Notes |
|------------|-------------------|-------------------|-------------|
| GPU-Z | https://www.techpowerup.com/gpuz/ | 建议 / Recommended | 单文件 exe，免安装 / Single exe, no install |
| CPU-Z | https://www.cpuid.com/softwares/cpu-z.html | 可选 / Optional | 下载 portable zip 版本 / Download portable zip |
| HWiNFO64 | https://www.hwinfo.com/download/ | 建议 / Recommended | 单文件 portable 版 / Single portable exe |
| FurMark | https://geeks3d.com/furmark/ | 建议 / Recommended | 需安装到 `tools/FurMark/` / Install to `tools/FurMark/` |
| OCCT | https://www.ocbase.com/download | 建议 / Recommended | 需安装到 `tools/OCCT/` / Install to `tools/OCCT/` |
| CrystalDiskInfo | https://crystalmark.info/en/software/crystaldiskinfo/ | 可选 / Optional | 解压到 `tools/CrystalDiskInfo/` |

---

## 输出说明 / Output Files

验机完成后，`output/<时间戳>/` 目录包含 / After verification, `output/<timestamp>/` contains:

| 文件 / File | 内容 / Content |
|------------|--------------|
| `system_info.txt` | 完整系统硬件信息（CPU/GPU/主板/内存）/ Full hardware info |
| `summary.txt` | 快速摘要 / Quick summary |
| `test_summary.txt` | 各测试步骤的通过/失败状态 / Pass/fail status per test |
| `dxdiag_output.txt` | DirectX 诊断信息 / DirectX diagnostic info |
| `session_transcript.log` | 完整运行日志 / Full run log |
| `furmark_log.txt` | FurMark GPU 测试日志 / FurMark test log |
| `occt_log.txt` | OCCT VRAM 测试日志 / OCCT VRAM test log |
| `cpu_stress_log.txt` | CPU 压力测试日志 / CPU stress test log |
| `memory_test_log.txt` | 内存稳定性测试日志 / Memory test log |
| `disk_health.txt` | 硬盘 SMART 健康报告 / Disk SMART health report |
| `thermal_stress_log.txt` | 散热综合评估日志 / Thermal stress log |
| `hwinfo_sensors.csv` | HWiNFO64 传感器时序数据（温度/功耗/频率）/ Sensor time-series data |
| `screenshot_*.png` | 测试前后及各阶段截图 / Before/after and mid-test screenshots |
| `../pc_check_<时间戳>.zip` | 以上所有文件的压缩包 / Archive of all above files |

---

## 最简配置（只用快速验机）/ Minimal Setup

如果时间有限，直接选 **[1] 快速验机**，无需任何额外工具，纯 PowerShell 即可完成。/
If time is limited, select **[1] Quick** mode at the menu — no extra tools needed, pure PowerShell.

---

## 完整配置（所有工具）/ Full Setup

```
tools/
  GPU-Z.exe
  cpuz_x64.exe
  HWiNFO64.exe
  FurMark/
    FurMark.exe
  OCCT/
    OCCT.exe
  CrystalDiskInfo/
    DiskInfo64.exe
```

选 **[3] 完整验机**，约 30-40 分钟完成全面检测。/
Select **[3] Full** mode — complete verification in ~30-40 minutes.

---

## 常见问题 FAQ

**Q: 运行时提示"此脚本无法运行"？/ "Script cannot be run" error?**
A: 右键 `run_windows_gui.bat`（或 `run_windows.bat`）→ "以管理员身份运行" / Right-click `run_windows_gui.bat` (or `run_windows.bat`) → "Run as Administrator"

**Q: 截图是黑屏？/ Screenshots are black?**
A: 部分系统的图形保护会阻止截图。手动截图（Win+Shift+S）保存到 `output/` 目录即可。/
Some systems block automated screenshots. Use Win+Shift+S manually and save to `output/`.

**Q: OCCT 为什么需要手动点击？/ Why does OCCT require a manual click?**
A: OCCT 免费版不支持完整命令行自动化。脚本会引导你完成操作步骤。/
The free version of OCCT does not support full CLI automation. The script will guide you through the steps.

**Q: 没有 OCCT/FurMark 也能用吗？/ Can I run without OCCT/FurMark?**
A: 可以。脚本有内置的 PowerShell 降级测试（CPU多线程数学循环 + 内存读写循环），功能有限但基本可用。/
Yes. The script includes PowerShell-native fallback tests when tools are missing.

**Q: 验机结果能造假吗？/ Can results be faked?**
A: 卖家本地运行无法保证 100% 防伪，建议买家在场或视频验机，结合型号序列号核实。/
Local execution cannot guarantee 100% authenticity. Buyers should attend in person or use video verification.

---

## 系统要求 / System Requirements

- Windows 10 / Windows 11
- PowerShell 5.0+（系统自带 / built-in）
- 4 GB 以上可用内存 / 4 GB+ available RAM

---

## License

MIT License — 详见 [LICENSE](LICENSE)
