# 🌟 GitHub Actions 源码阅读导航 (初二小白级)

你好！这份文档将带你走进“云端自动工厂”的世界。我们刚刚对你的 OpenWrt 编译流水线进行了“引擎升级”。

## 🏗️ 核心结构拆解

我们的流水线主要分布在 `.github/workflows/` 目录下。你可以把这里的 `.yml` 文件想象成**工厂的作业指导书**。

### 1. 📂 文件地图
- **`build-ALL-immortalwrt.yml`**: “豪华版”脚本，支持手动勾选不同机型。
- **`build-VIKINGYFY-*.yml`**: 针对特定机型的专用脚本。
- **`build-openwrt.yml`**: 基础通用版编译脚本。
- **`update-checker.yml`**: “巡逻哨”，专门负责检查源码有没有更新。

## 🚀 本次“引擎升级”亮点 (Node.js 24 适配)

### 🔴 痛点是什么？
GitHub 官方通知，老的 Node.js 20 引擎要退休了（Deprecated）。如果不升级，你的流水线顶端会一直挂着难看的黄色警告横幅。

### 🟢 我们做了什么？ (编程思想分析)

#### 🛡️ 强制切换引擎 (`env`)
我们在每个文件的 `env:` (全局变量) 区域加了一行：
```yaml
FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true
```
**解释**：这就像是直接给云端肉鸡的操作系统下达死命令：“不管别人怎么跑，我的脚本必须用最新的 24 号引擎！”。这不仅消除了警告，还让流水线更稳健。

#### 🆙 这种“大版本号”策略 (`@v2`)
我们将 `softprops/action-gh-release` 升级到了 `@v2`。
**解释**：
- `@v1` 就像是 Windows 95。
- `@v2.3.2` 就像是 Windows 11 的某个补丁版。
- **`@v2`** 就像是告诉系统：“请给我 Windows 11 系列里最新的、最好用的那个版本”。这样即使官方出了 `v2.4`，你的流水线也会自动跟进，非常省心。

#### 🧹 稳定清洁工 (`delete-older-releases`)
针对已经停止维护的清理工具，我们锁定了 `v0.3.4` 这个终极稳定版。配合上面的 Node.js 24 环境开关，它能继续在云端勤勤恳恳地扫地。

## 📖 阅读建议
如果你想深入学习，建议先看 [build-ALL-immortalwrt.yml](file:///d:/prj/mihhawork/Breeze-openwrt-ci-src/.github/workflows/build-ALL-immortalwrt.yml)，我在里面加了最全的中文注释，解释了什么是“If魔法”、什么是“买菜洗菜环节”。

---
*祝你的固件编译回回成功，永不翻车！* 🚀
