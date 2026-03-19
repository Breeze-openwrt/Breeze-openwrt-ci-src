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
2. **Action 版本更新**：
   - 将 `softprops/action-gh-release@v1` 或 `@v2.3.2` 统一修改为 `softprops/action-gh-release@v2`。
   - 将 `dev-drprasad/delete-older-releases@v0.2.0` 统一修改为 `dev-drprasad/delete-older-releases@v0.3.4`。
3. **极致中文注释**：
   为这些改动添加针对“初二编程小白”的保姆级中文注释，解释每一行代码背后的“防坑逻辑”和“编程思想”。

## 验证计划

### 自动化验证 (由于是 CI 配置，主要验证 YAML 语法)
- 使用 `action-validator` (如果本地有) 或通过检查修改后的 YAML 缩进和语法。
- **验证命令** (模拟检测):
  `yamllint .github/workflows/*.yml` (如果环境支持)

### 手动验证
- 请用户将代码推送至 GitHub 后，手动运行一次 `build-ALL-immortalwrt.yml` 工作流。
- 观察 Actions 运行日志中是否还存在关于 Node.js 20 弃用的 **黄条警告**。
- 确认 Release 能够正常生成且旧的 Release 能够按预期被清理。
