# 🚀 Breeze-openwrt-ci-src 流水线重构实施计划 (Implementation Plan)

## 📌 【项目背景：为什么要大改？】
想象一下，原本的 `.github/workflows/build-ALL-immortalwrt.yml` 就像是一张长达几百米的“清明上河图”。里面既有总指挥（决定编译哪个机型），也有包工头（负责清理原装空间），还有底层干活的建筑工人（执行几十行神秘的 Shell 代码）。这导致：
1. **改动极其危险**：只要一个缩进（多敲个空格）错了，整个几百行的系统瞬间崩溃罢工。
2. **复用率极低**：针对 Yashe 和 Taiyi，不得不把下载、编译的步骤复制粘贴两遍。
3. **无法单独测试**：几十行的复杂 Bash 脚本被困在 YAML 文件里，不能单独拿出来在本地运行测试。

### 🎯 我们的目标：打造成“微服务架构”的超级工厂！
向 `OpenWRT-CI` 学习，我们将执行**分封制**：
- **前台点单小妹**（原配的 `build-ALL-immortalwrt.yml`）：只负责显示网页菜单，问你要不要编译，然后把订单发给后厨。
- **公共微波炉/后厨组长**（新建的 `core-build.yml`）：专门接收单一机型的订单，不管你是 Yashe 还是 Taiyi，按标准化路数执行（下载、编译、打包、上传）。
- **专业清洁大妈与采购员**（新建的 `scripts/` 独立脚本群）：把以前混排在配置里的极品清仓指令，变成独立的 `.sh` 批处理文件。

---

## ⚠️ User Review Required (需要您审批的关键点)

> [!CAUTION]
> **史诗级重构警告**：这不仅是简单的格式微调，而是对整个流水线骨架的“换胸术”。
> 1. 我们会把原有的单体 `build-ALL-immortalwrt.yml` 拆骨，分离出一个被内部调用的 `core-build.yml`。
> 2. 会新建一个 `scripts` 文件夹存放外部化的高级 Bash 宏指令。
> 请确认这种**多文件协同**的架构是否符合您心目中完美代码的洁癖要求。

---

## 🛠️ Proposed Changes (我们要动哪些刀子？)

### 第一军团：将魔法咒语解封为独立脚本文件（Scripts Externalization）
这些文件将被存放在新增的 `scripts/` 目录中。我们会给每一个文件加上极其详细的“保姆级源码注释”。

#### [NEW] `scripts/clean_ubuntu.sh`(file:///d:/prj/mihhawork/Breeze-openwrt-ci-src/scripts/clean_ubuntu.sh)
- **职责**：将原来暴力拆除 `dotnet`、`android` 的十几行 `rm -rf` 逻辑封装在此处。只给 YAML 留一行调用命令。

#### [NEW] `scripts/init_env.sh`(file:///d:/prj/mihhawork/Breeze-openwrt-ci-src/scripts/init_env.sh)
- **职责**：包含熬底汤（海量 apt install）以及极其核心的“异星寻宝系统”（扫描出可用空间大于 20GB 的最佳附加盘符）机制。

#### [NEW] `scripts/ccache_manager.sh`(file:///d:/prj/mihhawork/Breeze-openwrt-ci-src/scripts/ccache_manager.sh)
- **职责**：专门用于发版成功后，调用 `gh api` 暴力清空老旧碎片金库王座的残尸，保证下次编译全套干净替换。

#### [NEW] `scripts/clean_releases.sh`(file:///d:/prj/mihhawork/Breeze-openwrt-ci-src/scripts/clean_releases.sh)
- **职责**：将批量删除 GitHub 死尸流水的 `xargs` 高并发命令封装成脚本。

---

### 第二军团：搭建“核心流水线”（Reusable Workflow Generation）

#### [NEW] `.github/workflows/core-build.yml`(file:///d:/prj/mihhawork/Breeze-openwrt-ci-src/.github/workflows/core-build.yml)
- **职责**：这是后厨真正的“炼钢炉”。使用 `on: workflow_call` 声明它是一个“可以被别人呼叫的代码块”。
- **参数解耦**：它不关心自己编译什么，它只接受传入参数。比如 `inputs.target_name` (机器名如 Yashe) 和 `inputs.config_file` (使用的配置文件如 `.configyashe`)。
- **消除重复**：原本针对 Yashe 和 Taiyi 复制了两遍的 `make download` 和 `eatmydata make -j$(nproc)` 将在这里仅仅出现一次。

---

### 第三军团：改造指挥部（Refactor The Monolith）

#### [MODIFY] `build-ALL-immortalwrt.yml`(file:///d:/prj/mihhawork/Breeze-openwrt-ci-src/.github/workflows/build-ALL-immortalwrt.yml)
- **职责变更**：完全卸任底层脏活累活。仅仅保留 `workflow_dispatch` 的前台交互菜单。
- **新流程**：获取菜单复选框的值，如果勾选了 Yashe，就下发命令调用 `core-build.yml` 传入 Yashe 参数；如果勾选了 Taiyi，又调用一次 `core-build.yml` 传入 Taiyi 参数，并行互不干扰！甚至会跑得更快（因为 GitHub Actions 会自动分配两台 2核 的云端机器帮你同时煮饭，突破了原先同一台机器串行煮饭的极限）！

---

## 🧪 Verification Plan (我们将如何验证没翻车？)

### Manual Verification (手工验证环节)
1. 首先，用 `shellcheck` 神器在本地把刚才提取的 `clean_ubuntu.sh`、`init_env.sh` 全部做一次语法严格审视，防止抽取出现环境变量未定义的低级错误。
2. 我们会提交代码到仓库，需要您去 GitHub Actions 的页面上，手动点一次 【Run Workflow】。
3. 观察点：
   - 是否分叉出了并行的子流水线？
   - “极品数据盘雷达”是否能够在脚本模式正常输出扫描到的可用大容量盘符？
   - 最终挂榜生成的 `Release` 固件产物，是否和之前一模一样好用。

---
请您审查该方案。如果没有异议，请在聊天中直接回复“通过”。我将立刻拿起手术刀开始动工！
