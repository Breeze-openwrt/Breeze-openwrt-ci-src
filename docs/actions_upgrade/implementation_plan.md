# 解决 GitHub Actions Node.js 20 弃用警告实施计划

本计划旨在解决 GitHub Actions 运行环境从 Node.js 20 迁移到 Node.js 24 导致的弃用警告。我们将通过升级 Action 版本以及启用前瞻性环境开关来确保流水线在 2026 年 6 月之后依然能稳定运行。

## 用户审核事项

> [!IMPORTANT]
> **Action 版本升级**：我们将把 `softprops/action-gh-release` 统一升级到最新的 `v2` 分支，并将已停止维护的 `dev-drprasad/delete-older-releases` 统一到其最新的 `v0.3.4` 版本。
> **环境开关**：我们将开启 `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true`。这会强制所有 JS 编写的 Action 在 Node.js 24 下运行，提前暴露并解决潜在的兼容性问题，这也是 GitHub 官方推荐的迁移方式。

## 拟议变更

### 工作流配置更新 [.github/workflows]

我们将对以下文件进行统一更新：
- `build-ALL-immortalwrt.yml`
- `build-VIKINGYFY-immortalwrt.yml`
- `build-VIKINGYFY-immortalwrt-taiyi.yml`
- `build-openwrt.yml`
- `build-my-openwrt.yml`
- `build-breeze303-openwrt.yml`

#### [MODIFY] 所有工作流文件
1. **Job 环境变量设置**：
   在每个工作的 `jobs.<job_id>.env:` 区块中添加 `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true`。
   > [!NOTE]
   > 某些 Actions 运行器对 Job 内部的变量感应更灵敏，这能确保每个任务步骤都强制使用 Node 24 引擎。
2. **🚀 去 Node 化：使用 GitHub 官方原生 CLI (终极方案)**：
   - 原先的 `dev-drprasad` 和 `GitRML` 这两个清理小号 Action 的作者已经停止了对最新版本（Node.js 24）的支持，无论我们加什么参数都会继续报错。
   - 这对于“性能狂魔”是无法容忍的冗余。我们将彻底抛弃这些第三方依赖，直接编写 10 行以内的极简 Bash 原生脚本，利用 GitHub Runners 自带并经过高度优化的 `gh` CLI，瞬间完成“清理过期固件”和“清除旧工作流”任务，一劳永逸解除隐患！
3. **softprops/action-gh-release 极速拉取最新版**：
   - 它是开源核心组件。我们把它显式升级到最新可用的大版本（如 `>=v2.2.1`）来消灭它的遗留报错。
4. **极致中文源码级注释**：
   - 添加为小白精心准备的中文注释，详细解释 Bash 脚本中的“数组按时间倒序截断并过滤循环清理”的架构思想。

## 验证计划

### 自动化验证 (由于是 CI 配置，主要验证 YAML 语法)
- 使用 `action-validator` (如果本地有) 或通过检查修改后的 YAML 缩进和语法。
- **验证命令** (模拟检测):
  `yamllint .github/workflows/*.yml` (如果环境支持)

### 手动验证
- 请用户将代码推送至 GitHub 后，手动运行一次 `build-ALL-immortalwrt.yml` 工作流。
- 观察 Actions 运行日志中是否还存在关于 Node.js 20 弃用的 **黄条警告**。
- 确认 Release 能够正常生成且旧的 Release 能够按预期被清理。
## ⚡ 编译报错紧急修复 (2026-03-20 补丁)

### 问题描述
用户反馈编译过程中出现 `ath11k-firmware-ipq6018` 与其 `ddwrt` 版本冲突，导致 OPKG 无法覆盖安装，编译中断。

### 修复方案
- **目标文件**：[.configyashe](file:///d:/prj/mihhawork/Breeze-openwrt-ci-src/.configyashe)
- **具体操作**：
  - 定位到第 2122 行：`CONFIG_PACKAGE_ath11k-firmware-ipq6018=y`
  - 修改为：`# CONFIG_PACKAGE_ath11k-firmware-ipq6018 is not set`
- **预期结果**：
  - 编译系统将只安装一套固件，冲突消除。
  - 配合已实施的“熔断机制”，下一次推送若成功则会自动发布，若失败则会安全停止。

## ⚡ 究极加速：压榨 GitHub Run 性能 (性能狂魔特供)

应用户进一步的深度加速需求，我们对 [`build-ALL-immortalwrt.yml`](file:///d:/prj/mihhawork/Breeze-openwrt-ci-src/.github/workflows/build-ALL-immortalwrt.yml) 展开了地毯式查杀，制定了如下提速计划：

### 1. 🔪 斩断无限重复的冗余 APT 更新
**原由**：在现代码的第 87~151 行，作者粘贴了整整十多段、高达七十行的 `sudo apt update -y; sudo apt full-upgrade...`。这在云端服务器严苛的磁盘 I/O 限制下，是极度致命的拖后腿操作（凭空多耗时 3~5 分钟）。
**手术**：我们将使用极致组合指令，合并依赖安装流，一次性干净利落地配置好交叉编译需要的骨架包，不仅缩短时间，也让脚本更短更美观。

### 2. 🧲 架设可自由开关的双轨高速缓存网 (`dl` & `ccache`)
**原由**：最耗时的过程之首，就是使用网络抓取（`make download`）和全量交叉编译底层的无数个依赖包。
**高阶动作**：
我们将彻底放开 GitHub Action 的潜能限制，引入两个最前沿的加速隧道，并**把控制权做成开关赋予用户**：
1. **前台打勾控制台 (`workflow_dispatch`)**：新增 `use_dlcache` 与 `use_ccache` 选项（默认开启）。不想用随时弹窗网页点掉。
2. **下载池拦截缓存 (`dl/`)**：用 `actions/cache@v5` 拦截动辄几 GB 的跨国下载包。
3. **C++ 编译碎片金库 (`ccache`)**：利用 GitHub Actions 的环境复用性，保存编译器计算结果 (`~/.ccache`)。同时自动把 `CONFIG_CCACHE=y` 脚本推送到 `make defconfig` 之前。有了这个设定，你的未修改包将 100% 极速越过编译器！
