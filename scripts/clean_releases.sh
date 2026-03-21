#!/bin/bash

# =========================================================================================
# 🎓【初二小白课堂：源码阅读与赏析】 - clean_releases.sh
# 
# 📘【剧本背景】：
# 我们不想在 GitHub 的发版页面（Releases）和流水线记录留存下一千年前的老化石。
# 但如果你一条一条去网页上点删除，手指头都要点断。
#
# 🕵️‍♂️【作者意图】：
# 把以前需要在 YML 里面长达几十行的请求并发与数组组装，做成了外部脚本。
# 彻底实现高并发批量连带删除，避免 GitHub API 请求节流降速！
# =========================================================================================

echo "⚠️ 启动流水线僵尸记录绞肉机..."
# `gh run list`：提取我们的流水线（Action 回放）所有记录。
# `--limit 500`：最多拉最近的500具行尸走肉。
# `--json databaseId`：只要它们的数字身份证。
# `-q '.[].databaseId'`：用原生 jq 库极其强悍的语法精确抽选身份证串！
# `tail -n +36`：从第 36 具开始斩！前 35 次最新最猛的操作保留给人们瞻仰！
# `xargs -r`：【高并发屠杀术】，原本是一刀杀一个，加上此咒语后自动合成为无敌剑阵，把所有的 ID 一口气送往 `gh run delete`，只需发 1 次请求全部斩平死亡。
gh run list --limit 500 --json databaseId -q '.[].databaseId' | tail -n +36 | xargs -r gh run delete || true

if [ "$UPLOAD_RELEASE" == "true" ]; then
  echo "⚠️ 启动废弃固件旧版发布清除仪..."
  # 同样地，把前 30 个历史王座的发布留给时光倒流的回退保底
  tags=$(gh release list -L 100 | awk -F '\t' '{print $1}' | tail -n +31)
  
  # `[-n "$tags"]`：如果你抓取到的待斩名单不为空
  if [ -n "$tags" ]; then
    for tag in $tags; do
      echo "🗑️ 正在清除史前发版: $tag"
      # `delete "$tag"` = 删除。 `--cleanup-tag` = 拔草除根！连那个只剩个空架子的签条 tag 都抹掉。
      # `-y` = yes! 闭眼连开！不要询问确认！
      gh release delete "$tag" --cleanup-tag -y || true
    done
  fi
fi
