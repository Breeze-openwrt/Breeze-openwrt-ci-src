# 任务追踪 (原子级清理老缓存)

- [x] 分析 Github Actions 缓存生成后如何安全清除残留的机制
- [/] 在 `build-ALL-immortalwrt.yml` 尾部添加 `if: success()` 强力清空多余前缀缓存的步骤
- [ ] 编写并同步说明文档更新至 Walkthrough
