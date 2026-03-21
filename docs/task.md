# Breeze-openwrt-ci-src 优化任务清单

- [x] 1. 分析与评估
  - [x] 读取 `OpenWRT-CI` 的核心流水线 `WRT-CORE.yml` 及其脚本结构。
  - [x] 读取 `Breeze-openwrt-ci-src` 的流水线 `build-ALL-immortalwrt.yml` 逻辑。
  - [x] 总结两个项目的差异并在聊天中回复探讨优化点。
- [x] 2. 编写优化建议 (Draft Optimization Plan)
  - [x] 讨论模块化架构改造（拆分 Workflow）。
  - [x] 讨论内联 Shell 脚本外部化。
  - [x] 探讨环境变量与元数据管理的规范化。
- [x] 3. 制定 Implementation Plan 
  - [x] 结合用户反馈，提供具体的代码重构方案 (implementation_plan.md)。
- [x] 4. 开始重构 (Pending Review)
  - [x] 等待用户确认 Implementation Plan。
  - [x] 提取各个脚本到 scripts 目录。
  - [x] 拆解并重写 Action 工作流文件。
