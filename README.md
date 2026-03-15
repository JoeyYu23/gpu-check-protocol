# GPU Check Protocol

**二手电脑 / 显卡交易验机工具**

一键收集 GPU 硬件信息、运行压力测试、打包结果，帮助买卖双方在交易现场快速完成验机。

---

## 安全声明

- **不联网、不上传**：所有数据只保存在本机 `output/` 目录，不发送到任何服务器
- **不访问个人文件**：只读取硬件信息（型号、驱动版本、温度），不碰文档、图片、密码
- **不留后台服务**：脚本运行完毕即结束，不安装任何常驻程序
- **不修改系统设置**（除 HWiNFO64 的 CSV 记录注册表项，测试后可手动删除）
- **开源可审计**：所有 `.ps1` 脚本均为明文 PowerShell，可用记事本打开查看

---

## 快速开始（3步）

### 第一步：下载本工具

```
git clone https://github.com/JoeyYu23/gpu-check-protocol.git
```

或直接在 GitHub 页面点 **Code → Download ZIP**，解压到任意目录。

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

## 工具下载链接

| 工具 | 下载地址 | 是否必须 | 说明 |
|------|---------|---------|------|
| GPU-Z | https://www.techpowerup.com/gpuz/ | 建议 | 单文件 exe，免安装 |
| CPU-Z | https://www.cpuid.com/softwares/cpu-z.html | 可选 | 下载 portable zip 版本 |
| HWiNFO64 | https://www.hwinfo.com/download/ | 建议 | 单文件 portable 版 |
| FurMark | https://geeks3d.com/furmark/ | 建议 | 需安装，安装到 `tools/FurMark/` |
| OCCT | https://www.ocbase.com/download | 建议 | 需安装，安装到 `tools/OCCT/` |

---

## 输出说明

验机完成后，`output/<时间戳>/` 目录包含：

| 文件 | 内容 |
|------|------|
| `system_info.txt` | 完整系统硬件信息（CPU/GPU/主板/内存） |
| `summary.txt` | 一行摘要，便于快速查看 |
| `test_summary.txt` | 各测试步骤的通过/失败状态 |
| `dxdiag_output.txt` | DirectX 诊断信息（含详细显卡信息） |
| `session_transcript.log` | 完整运行日志 |
| `furmark_log.txt` | FurMark 测试日志（开始/结束/退出码） |
| `occt_log.txt` | OCCT 测试日志 |
| `hwinfo_sensors.csv` | HWiNFO64 传感器时序数据（温度/功耗/频率） |
| `screenshot_*.png` | 测试前后截图 |
| `../gpu_check_<时间戳>.zip` | 以上所有文件的压缩包 |

---

## 最简配置（只用 GPU-Z + FurMark）

如果时间有限，只放这两个工具：

```
tools/
  GPU-Z.exe
  FurMark/
    FurMark.exe
```

编辑 `config/benchmark_config.json`，将 `enable_occt` 改为 `false`：

```json
{
  "enable_occt": false,
  "enable_furmark": true,
  "furmark_duration_sec": 300
}
```

双击 `run_windows.bat`，5分钟内完成基础验机。

---

## 完整配置（所有工具）

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

保持 `config/benchmark_config.json` 默认配置，完整验机约 15-20 分钟。

---

## 常见问题 FAQ

**Q: 运行时提示"此脚本无法运行"？**
A: 右键 `run_windows.bat` → "以管理员身份运行"，或在开始菜单搜索 PowerShell，右键以管理员运行。

**Q: 截图是黑屏？**
A: 部分系统的图形保护会阻止截图。手动截图（Win+Shift+S）保存到 `output/` 目录即可。

**Q: FurMark 没有 `/nogui` 参数怎么办？**
A: 不同版本 FurMark 参数略有差异。脚本会尝试启动，失败时会打印提示，手动操作即可。

**Q: OCCT 为什么需要手动点击？**
A: OCCT 免费版不支持完整命令行自动化。脚本会引导你完成操作步骤。

**Q: 验机结果能造假吗？**
A: 卖家本地运行无法保证 100% 防伪，建议买家在场或视频验机，结合型号序列号核实。

**Q: 工具文件不在 tools/ 里可以吗？**
A: 不行，脚本按固定路径查找。请按 README 表格放置。

---

## 系统要求

- Windows 10 / Windows 11
- PowerShell 5.0+（系统自带）
- 4 GB 以上可用内存（FurMark 压测期间）

---

## License

MIT License — 详见 [LICENSE](LICENSE)
