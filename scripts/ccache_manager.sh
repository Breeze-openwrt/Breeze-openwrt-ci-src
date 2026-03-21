#!/bin/bash

# =========================================================================================
# 🎓【初二小白课堂：源码阅读与赏析】 - ccache_manager.sh (回归大道至简版)
# 
# 📘【剧本背景】：
# 因为大老板发话了，Yashe和Taiyi本来就是同门师兄弟，底子一样，为什么要分开干？
# 所以我们取消了它们的独栋别墅，让它们共用一套顶级编译环境。
# 既然吃穿住用行都在一块了，那存金丹的盒子也用回一个最大的！
#
# 🕵️‍♂️【作者意图】：
# 因此阿姨清理的靶标不再是各自独立的名字，而是唯一的 `shared-latest` 同源大库王座。
# =========================================================================================

echo "🔍 正在执行极简化缓存策略：抹除云端 [同源大库 shared] 的 ccache，为新金丹腾挪空位..."

gh api -X GET /repos/${GITHUB_REPOSITORY}/actions/caches?key=${RUNNER_OS}-openwrt-ccache-shared-latest \
  | jq -r '.actions_caches[].id' \
  | awk '{if ($1) system("gh api -X DELETE /repos/'${GITHUB_REPOSITORY}'/actions/caches/" $1)}' || true
  
gh api -X GET /repos/${GITHUB_REPOSITORY}/actions/caches?per_page=100 \
  | jq -r '.actions_caches[] | select(.key | startswith("${RUNNER_OS}-openwrt-ccache-shared-")) | .id' \
  | awk '{if ($1) system("gh api -X DELETE /repos/'${GITHUB_REPOSITORY}'/actions/caches/" $1)}' || true
  
echo "🎉 属于同源双子星的旧王座已被彻底清空！大家共吃一锅饭，效率拉满！"
