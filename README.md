# GPU Check Protocol

**二手电脑 / 显卡交易验机工具**

一键收集 GPU 硬件信息、运行压力测试、打包结果，帮助买卖双方在交易现场快速完成验机。适用于各类 NVIDIA 显卡（RTX 4090/4080/3090/3080/3070 等）。

**Used-GPU / PC verification tool for buyers and sellers — collects hardware info, runs stress tests, and packages results. Works with any NVIDIA GPU (RTX 4090/4080/3090/3080/3070, etc.).**

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

## 快速开始（3步）

### 第一步：下载本工具

从 GitHub 页面点 **Code → Download ZIP**，解压到任意目录。

### 第二步：下载测试工具

将以下工具放入 `tools/` 目录（见下方下载链接表）：

| 工具 | 放置路径 | 用途 |
|------|---------|------|
| GPU-Z.exe | `tools/GPU-Z.exe` | 显卡信息读取 |
| cpuz_x64.exe | `tools/cpuz_x64.exe` | CPU/内存信息 |
| HWiNFO64.exe | `tools/HWiNFO64.exe` | 传感器实时记录 |
| FurMark.exe | `tools/FurMark/FurMark.exe` | GPU 烤机压力测试 |
| OCCT.exe | `tools/OCCT/OCCT.exe` | 显存压力测试 |

### 第三步：运行验机

**双击 `run_windows.bat`**（推荐右键"以管理员身份运行"以获取完整硬件数据）

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
| HWiNFO64.exe | `tools/HWiNFO64.exe` | Real-time sensor logging |
| FurMark.exe | `tools/FurMark/FurMark.exe` | GPU stress test |
| OCCT.exe | `tools/OCCT/OCCT.exe` | VRAM stress test |

### Step 3: Run verification

**Double-click `run_windows.bat`** (recommended: right-click → "Run as Administrator" for full hardware data)

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
| `furmark_log.txt` | FurMark 测试日志 / FurMark test log |
| `occt_log.txt` | OCCT 测试日志 / OCCT test log |
| `hwinfo_sensors.csv` | HWiNFO64 传感器时序数据（温度/功耗/频率）/ Sensor time-series data |
| `screenshot_*.png` | 测试前后截图 / Before/after screenshots |
| `../gpu_check_<时间戳>.zip` | 以上所有文件的压缩包 / Archive of all above files |

---

## 最简配置（只用 GPU-Z + FurMark）/ Minimal Setup

如果时间有限，只放这两个工具 / If time is limited, only these two tools are needed:

```
tools/
  GPU-Z.exe
  FurMark/
    FurMark.exe
```

编辑 `config/benchmark_config.json`，将 `enable_occt` 改为 `false` /
Edit `config/benchmark_config.json`, set `enable_occt` to `false`:

```json
{
  "enable_occt": false,
  "enable_furmark": true,
  "furmark_duration_sec": 300
}
```

双击 `run_windows.bat`，5分钟内完成基础验机。/
Double-click `run_windows.bat` — basic verification completes in ~5 minutes.

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
```

保持 `config/benchmark_config.json` 默认配置，完整验机约 15-20 分钟。/
Keep `config/benchmark_config.json` at defaults — full verification takes ~15-20 minutes.

---

## 常见问题 FAQ

**Q: 运行时提示"此脚本无法运行"？/ "Script cannot be run" error?**
A: 右键 `run_windows.bat` → "以管理员身份运行" / Right-click `run_windows.bat` → "Run as Administrator"

**Q: 截图是黑屏？/ Screenshots are black?**
A: 部分系统的图形保护会阻止截图。手动截图（Win+Shift+S）保存到 `output/` 目录即可。/
Some systems block automated screenshots. Use Win+Shift+S manually and save to `output/`.

**Q: FurMark 没有 `/nogui` 参数怎么办？/ FurMark doesn't accept `/nogui`?**
A: 不同版本 FurMark 参数略有差异。脚本会尝试启动，失败时会打印提示，手动操作即可。/
Parameter support varies by FurMark version. The script will print a prompt if it fails — follow the manual steps.

**Q: OCCT 为什么需要手动点击？/ Why does OCCT require a manual click?**
A: OCCT 免费版不支持完整命令行自动化。脚本会引导你完成操作步骤。/
The free version of OCCT does not support full CLI automation. The script will guide you through the steps.

**Q: 验机结果能造假吗？/ Can results be faked?**
A: 卖家本地运行无法保证 100% 防伪，建议买家在场或视频验机，结合型号序列号核实。/
Local execution cannot guarantee 100% authenticity. Buyers should attend in person or use video verification and cross-check serial numbers.

**Q: 工具文件不在 tools/ 里可以吗？/ Can tools be placed elsewhere?**
A: 不行，脚本按固定路径查找。请按上方表格放置。/
No — the scripts look for tools at fixed paths. Follow the placement table above.

---

## 系统要求 / System Requirements

- Windows 10 / Windows 11
- PowerShell 5.0+（系统自带 / built-in）
- 4 GB 以上可用内存（FurMark 压测期间 / during FurMark stress test）

---

## License

MIT License — 详见 [LICENSE](LICENSE)
