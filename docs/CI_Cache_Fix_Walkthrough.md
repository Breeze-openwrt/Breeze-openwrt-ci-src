# CI Workflow 缓存机制修复全过程赏析

## 问题回顾
在执行 OpenWrt CI 编译时，遇到了以下两个痛点：
1. **只生成了 `Linux-openwrt-dl`，没生成 `Linux-openwrt-ccache-`**。
2. **在“不使用旧缓存”的情况下，系统并未自动删除旧缓存，而是生成了两个不同文件名的缓存并存**。

---

## 源码探秘与根因分析

### 痛点 1：为何 Ccache 没有被保存？
在通常的 Linux 环境中，Ccache 会默认把缓存数据塞在当前用户的宿主目录，即 `~/.ccache`。所以原先我们的配置是：
```yaml
path: ~/.ccache
```
**但是！**(敲黑板) OpenWrt 并非普通软件，它是一整套复杂的交叉编译生态。OpenWrt 原生设定了一个极其霸道的专属规则：**它的 ccache 数据默认存放在当前代码树下的 `.ccache` 目录中**（也就是由于我们进入了 openwrt 目录，实际路径为 `openwrt/.ccache`）。
由于 Actions 寻找了错误的 `~/.ccache`，自然什么碎片都没收集到，所以打包出来的缓存总是空的，当然就不会生成缓存包了！

### 痛点 2：为何“取消缓存”会生成双份异名垃圾？
最初为了满足“不使用旧缓存并重新下载”的功能，代码中采用了加入 `github.run_id` 乱码后缀的形式来强行避开旧缓存的读取：
```yaml
key: ${{ runner.os }}-openwrt-dl-... || github.run_id
```
**致命机理分析**：
GitHub Actions 的 [`actions/cache`](https://github.com/actions/cache) 插件有一个底层铁砧规则：**缓存一旦生成，其 Key 就是完全只读和被锁死的（Immutable），它自身绝对不会“覆盖”或“删除”旧名的缓存**。
当你取消勾选时，由于使用了唯一的 `run_id`，它就保存了一份名叫 `...-1234567` 的新缓存。而原来名为 `...-<hash>` 的旧缓存毫发无损地依然存活在你的仓库里。这就导致了“两个异名缓存横空并存”。更糟糕的是，下次你再次勾选“使用缓存”时，它依然会傻乎乎地去读取那个老的 `<hash>` 缓存，而你新生成的完全起不到覆盖更新的作用！

---

## 优雅的修复方案设计

为了兼顾性能狂魔与测试友好的极致体验，我们做了以下史诗级改动：

### 1. 拨乱反正，校对 Ccache 黄金罗盘
我们将 Ccache 的捕获路径由 `~/.ccache` 修正为原生正宗的：
```yaml
path: openwrt/.ccache
```

### 2. 引入智能“洗锅”特警队 (gh api)
我们不再搞花里胡哨的乱码后缀，而是始终使用最标准、最干净的名字（由 feeds.conf.default 的 Hash 决定）。一旦用户选择“不使用旧缓存(false)”，我们在读取缓存流的前夕，提前执行一段**黑魔法**：
```bash
gh api -X GET /repos/${{ github.repository }}/actions/caches?per_page=100 \
  | jq -r '.actions_caches[] | select(.key | contains("openwrt-dl")) | .id' \
  | xargs -I {} gh api -X DELETE /repos/${{ github.repository }}/actions/caches/{}
```
**代码解析与赏析**：
- `gh api`: 原生调用 GitHub 内部接口，速度极快（且由于我们本就在 GitHub 机房内，基本属于光速内网交互）。
- `jq -r`: 解析 JSON 结构，提取出所有名字包含了我们需要销毁特征词（如 `openwrt-dl`）的过期尸体 ID。
- `xargs -I {} gh api -X DELETE`: 发送“精准制导轰炸指令”，将这批历史旧账直接由内而外彻底湮灭！

**修复后的美妙之处**：
现在的 Actions，如果勾选了“不使用旧缓存”，它会首先利用 GitHub API **主动彻底销毁**旧有记录以腾出极大空间。随后在执行完毕时，将新下载的 `dl` 或产生的新 `ccache`，**光明正大且唯一地**写入为最正统的标准名字。

### 3. 【终极杀招】打扫战场：原子性销毁历史旧残余
为了满足“绝不残留任何同前缀垃圾”的性能狂魔级需求，我们在整个流水线的最末端（执行 `actions/cache` 保存新金库之前的最后一秒），安插了一支清剿护卫队：
```yaml
      - name: 🧹 Atomically Purge Old Caches # 🧹 原子性销毁旧缓存残留
        if: success()
        # 提取当前生成的专属目标名字 (保留名单)
        env:
          DL_KEY_KEEP: ${{ runner.os }}-openwrt-dl-${{ hashFiles('openwrt/feeds.conf.default') }}
          ...
        run: |
          gh api -X GET /repos/${{ github.repository }}/actions/caches?per_page=100 \
            | jq -r --arg keep "$DL_KEY_KEEP" '.actions_caches[] | select(.key | startswith("Linux-openwrt-dl-")) | select(.key != $keep) | .id' \
            | xargs -I {} gh api -X DELETE /repos/${{ github.repository }}/actions/caches/{}
```
**深度逻辑赏析与原子性保障**：
- **`if: success()`**：这是最强的一把锁！只有当你这套代码顺利且完美地跑完编译，证明即将会向云端保存“优秀结晶”时，它才会启动销毁机制。如果编译中途失败，旧的缓存保留，不会导致你鸡飞蛋打。
- **动态白名单拦截**：通过 `--arg keep "$DL_KEY_KEEP"` 将我们本次最终生成的目标包名作为“免死金牌”传入 `jq`。
- **`select(.key | startswith(...)) | select(.key != $keep)`**：提取出云端存在的所有同前缀旧包（意味着它是上古时代的垃圾缓存），但是**坚决跳过我们本次要保存的那唯一一个本体**。
- **时间节点的完美契合**：此步骤位于所有正式步骤之尾。由于 `actions/cache` 插件的设计特性是“利用隐藏在步骤底层的 post-action 来进行最终上传”，所以我们在它即将上传的前一秒拔刀，清除掉天下所有阻碍。于是下一秒，云端仅会接受最纯净的这一份传承！

再也不会有空间被撑爆，再也不会有各种怪咖版本的前缀垃圾堆积如山！你的 CI 流水线现在变得极其致命又极其优雅！
