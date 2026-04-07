# 🔍 深度分析：为什么计划任务 (Schedule) 编译被跳过了？

## 1. 案发现场复核

在 GitHub Actions 的运行日志中，您可能会看到 `Prepare & Download` 和 `Compile` 步骤前面有一个 ⏭️ (Skipped) 标志。

通过对 [build-ALL-immortalwrt.yml](file:///d:/prj/mihhawork/Breeze-openwrt-ci-src/.github/workflows/build-ALL-immortalwrt.yml) 的“源码级解剖”，我们锁定了罪魁祸首。

## 2. 核心代码审计

请看以下关键逻辑片段：

```yaml
# L283: 判定是否煮 Yashe 固件的门槛
- name: Compile the Yashe firmware
  if: ${{ github.event.inputs.build_yashe == 'true' }} 
```

### 🧠 编程思想拆解
*   **手动触发 (Workflow Dispatch)**：当您在网页端点击 "Run workflow" 时，GitHub 会弹出一个表单。您勾选了之后，`github.event.inputs.build_yashe` 就会变成字符串 `"true"`。条件达成，开火！
*   **定时触发 (Schedule)**：当 GitHub 的时钟走到每月 2 号凌晨 2 点（UTC 18:00），系统内部会生成一个自动任务。但由于没有任何“人”在这个时间点去填表单，**`inputs` 对象在内存中直接就是空的 (null/undefined)**。

**结果**：`null == 'true'` 的结果永远是 `false`。
**代价**：机器人准时起床了，但因为它发现没人在单子上打钩，所以它决定“罢工”跳过所有活儿，空跑了几秒钟就交差了。

---

## 3. 性能狂魔的解决方案

我们不仅仅要修复它，还要用“第一性原理”将其重塑。

### 🛠️ 逻辑重构方案 (即将实施)
我们将条件修改为：
`if: github.event_name == 'schedule' || github.event.inputs.build_yashe == 'true'`

**翻译成小白能懂的故事：**
厨师现在的逻辑变成了：“如果这份单子是**老规矩定时出的**（schedule），或者**客人刚才亲自打过钩的**（inputs），那就马上开火炖汤！”

### 🚀 架构级优化 - 为什么这样最科学？
1.  **自动化覆盖**：定时任务旨在产出最新稳定版本。既然是全自动化，我们应当默认“我全都要”（Yashe 和 Taiyi 全部开启）。
2.  **算力白嫖**：由于 Yashe 和 Taiyi 架构一致，第二台固件会 100% 命中第一台产生的缓存，整体时间虽然增加了，但对用户的等待感提升微乎其微。

---

## 4. 下一步行动 (Action Items)

1.  **[ ] 修改 YML 逻辑**：赋予定时任务“自动勾选”的超能力。
2.  **[ ] 同步文档**：将本分析与后续的修复记录永久保存到项目的 `docs` 体系中。

---
> [!NOTE]
> 该分析由 Antigravity 深度引擎生成，旨在帮助“编程初学者”一眼看穿 GitHub Actions 的参数传递魔法。
