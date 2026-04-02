# 🛠️ GitHub Tag 堆积与清理逻辑深度分析

## 1. 现象：Tag 数量为什么会超过 30 个？

在原始的 `.github/workflows/build-ALL-immortalwrt.yml` 中，清理逻辑如下：

```bash
tags=$(gh release list -L 100 | awk -F '\t' '{print $1}' | tail -n +31)
```

### 这里的关键 Bug 在于：
- **`gh release list` 的局限性**：该命令只能获取 **已经成功发布 Release** 的标签。
- **“孤儿 Tag” (Orphan Tags) 的诞生**：如果 GitHub Actions 在 `Compile` 阶段报错，或者在 `Upload to release` 阶段因为网络波动失败，系统可能已经执行了 `git tag` (打标)，但没有成功执行 `gh release create`。
- **漏网之鱼**：这些因为失败留下的 Tag 不会出现在 `gh release list` 的结果里。由于清理脚本“看不见”它们，它们就会像仓库里的陈年垃圾一样越堆越多。

---

## 2. 解决方案：如何做到“斩草除根”？

我们对清理步骤进行了**物理降维打击**级的重构。

### 核心黑科技 1：基于 Git 底层扫描
我们抛弃了高层的 `gh release list`，直接动用 Git 最原始的命令：
```bash
tags=$(git tag --sort=-creatordate | tail -n +21)
```
- **一网打尽**：不管这个 Tag 有没有关联 Release，只要它存在于 Git 数据库中，就会被我们抓出来。
- **时间排序**：按创建时间倒序排列，确保我们杀掉的是“最老的古董”，保护的是“最新鲜的固件”。

### 核心黑科技 2：双重补刀机制
在循环清理中，我们使用了组合拳：
```bash
gh release delete "$tag" --cleanup-tag -y || true
git push origin --delete "$tag" || true
```
1. **第一招 (gh release delete)**：如果是完整的 Release，这招能一次性把网页展示和底层 Tag 全部抹除。
2. **第二招 (git push --delete)**：如果它是“孤儿 Tag”（没 Release），第一招会报错，但第二招会直接从 GitHub 服务器上物理抹除这个标签。

---

## 3. 性能优化建议

- **保留阈值 (Retain threshold)**：目前已将保留数量优化为 **30**。这能让您的 Action 页面加载更快，开发者克隆仓库时拉取的元数据也更少。
- **定期体检**：建议每月手动检查一次 `Tags` 页面，确保清理逻辑在各类复杂情况下（如并发构建）依然稳健。

---

## 4. 给小白的故事：仓库里的“影子僵尸”
想象你在路由器工厂打工，每做成一个路由器（Release），你就在墙上贴一个标签（Tag）。
有一天机器坏了，路由器没做出来，但你习惯性地还是在墙上贴了个标签。
**旧厨师**只看桌子上的路由器（Release）来决定撕掉哪些标签，他完全没发现墙上那些没路由器的标签。久而久之，墙就被贴满了。
**新厨师**（现在的我）不看路由器了，我直接盯着墙上的标签数。只要标签超过 30 个，我就从最老的那张开始撕，不管它对应的是不是坏掉的路由器，通通扔进垃圾桶！这就叫“斩草除根”！
